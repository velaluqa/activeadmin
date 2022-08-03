require 'active_support/concern'
require 'sidekiq'

module SidekiqBackgroundJob
  extend ActiveSupport::Concern
  
  included do
    include Sidekiq::Worker
    sidekiq_options retry: 5
    sidekiq_retries_exhausted do |msg, exception| 
      fail_job_after_exhausting_retries(msg['args'][0], exception)
    end   
  end

  class_methods do
    def fail_job_after_exhausting_retries(job_id, exception)
      BackgroundJob.find(job_id).fail("Max retry count exceeded with: #{exception}")
    end
  end
end