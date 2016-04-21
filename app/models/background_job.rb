##
# A simple model to hold information about background jobs.
class BackgroundJob < ActiveRecord::Base
  belongs_to :user

  before_destroy :remove_zipfile

  scope :completed, -> { where(completed: true) }
  scope :running, -> { where(completed: false) }

  ##
  # Find out whether this job has finished.
  #
  # @returns [Boolean] whether this job has finished
  #
  # TODO: Refactor to use `completed_at` as indicator for completed jobs.
  def finished?
    completed
  end

  ##
  # Find out whether this job has failed.
  #
  # @returns [Boolean] whether this job has failed
  def failed?
    completed && !successful
  end

  ##
  # Save this BackgroundJob as successful.
  #
  # @param [Hash] optional results hash
  def finish_successfully(results = {})
    finish

    self.successful = true
    self.results = results

    save
  end

  ##
  # Save this BackgroundJob as failed.
  #
  # @param [String] the error message
  def fail(error_message)
    finish

    self.successful = false
    self.error_message = error_message

    save
  end

  ##
  # Save this BackgroundJob's progress.
  #
  # @param [Integer] the current amount done
  # @param [Integer] the amount for completion
  def set_progress(current, total)
    self.progress = current.to_f / total.to_f
    save
  end

  protected

  ##
  # Update this job as completed.
  #
  # TODO: Refactor to use `completed_at` as sole completion
  # indicator.
  #
  # @param [Boolean] whether to save the model (default: false)
  def finish(save = false)
    self.completed = true
    self.completed_at = Time.now

    self.save if save
  end

  ##
  # If the job is finished and it has a zipfile referenced in its
  # `results` remove the file upon deletion of the resource.
  def remove_zipfile
    return false unless finished?

    File.delete(results['zipfile']) if results.andand['zipfile']
  rescue => error
    logger.warn(error)
  end
end
