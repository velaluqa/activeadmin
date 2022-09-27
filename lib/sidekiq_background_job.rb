require 'active_support/concern'
require 'sidekiq'

module SidekiqBackgroundJob
  extend ActiveSupport::Concern

  class Cancellation < StandardError; end
  class Error < StandardError; end

  included do
    include Sidekiq::Worker

    sidekiq_options retry: 5
    sidekiq_retries_exhausted do |msg, exception|
      fail_job_after_exhausting_retries(msg['args'][0], exception)
    end

    def job_id
      @job.id
    end

    def perform_job(**args)
      throw "Worker not implemented"
    end

    def perform(job_id, *args)      
      @progress_total = 1
      @progress = 0
      @job = BackgroundJob.find(job_id)

      return cancel_worker! if cancelling?

      ::PaperTrail.request.whodunnit = @job.user_id

      # Execute original implementation of the background job worker.
      perform_job(*args)
    rescue SidekiqBackgroundJob::Cancellation => error
      @job.confirm_cancelled!
    rescue SidekiqBackgroundJob::Error => error
      @job.fail!(error.message)
    ensure
      ::PaperTrail.request.whodunnit = nil
    end

    def set_progress_total!(total)
      @progress_total = total
      @job.set_progress(@progress, @progress_total)
    end

    def increment_progress!(value = 1)
      @progress += value
      @job.set_progress(@progress, @progress_total)
    end

    def set_progress!(value)
      @progress = value
      @job.set_progress(@progress, @progress_total)
    end

    def succeed!(result = {})
      @job.succeed!(result)
    end

    def fail!(message)
      @job.fail!(message)
    end

    def cancel_worker!
      raise SidekiqBackgroundJob::Cancellation
    end
    
    def cancelling?
      @job.reload
      @job.cancelling?
    end

    class << self
      alias_method :perform_async_without_job, :perform_async 
      def perform_async(*args)
        options = args.extract_options!

        background_job = BackgroundJob.create(options)

        perform_async_without_job(background_job.id, *args)

        background_job
      end
    end
  end

  class_methods do
    extend Sidekiq::Worker::ClassMethods

    def fail_job_after_exhausting_retries(job_id, exception)
      BackgroundJob.find(job_id).fail!("Max retry count exceeded with: #{exception}")
    end
  end
end
