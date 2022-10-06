##
# A simple model to hold information about background jobs.
#
# ## Schema Information
#
# Table name: `background_jobs`
#
# ### Columns
#
# Name                 | Type               | Attributes
# -------------------- | ------------------ | ---------------------------
# **`completed`**      | `boolean`          | `default(FALSE), not null`
# **`completed_at`**   | `datetime`         |
# **`created_at`**     | `datetime`         |
# **`error_message`**  | `text`             |
# **`id`**             | `integer`          | `not null, primary key`
# **`legacy_id`**      | `string`           |
# **`name`**           | `string`           | `not null`
# **`progress`**       | `float`            | `default(0.0), not null`
# **`results`**        | `jsonb`            | `not null`
# **`successful`**     | `boolean`          |
# **`updated_at`**     | `datetime`         |
# **`user_id`**        | `integer`          |
#
# ### Indexes
#
# * `index_background_jobs_on_completed`:
#     * **`completed`**
# * `index_background_jobs_on_legacy_id`:
#     * **`legacy_id`**
# * `index_background_jobs_on_name`:
#     * **`name`**
# * `index_background_jobs_on_results`:
#     * **`results`**
# * `index_background_jobs_on_user_id`:
#     * **`user_id`**
#
class BackgroundJob < ApplicationRecord
  belongs_to :user, optional: true

  before_destroy :remove_zipfile

  scope :completed, -> { where(completed: true) }
  scope :running, -> { where(completed: false) }

  scope :granted_for, ->(options = {}) {
    user = options[:user] || raise("Missing 'user' option")
    return all if user.is_root_user?
    where(user_id: options[:user].id)
  }

  scope :searchable, -> { select(<<SELECT.strip_heredoc) }
    NULL::integer AS study_id,
    NULL::varchar AS study_name,
    background_jobs.name AS text,
    background_jobs.id::varchar AS result_id,
    'BackgroundJob'::varchar AS result_type
SELECT

  after_save :broadcast_job_update

  enum(
    state: {
      scheduled: "scheduled",
      running: "running",
      successful: "successful",
      failed: "failed",
      cancelling: "cancelling",
      cancelled: "cancelled"
    }
  )

  def broadcast_job_update
    ActionCable.server.broadcast(
      "background_jobs_channel",
      job_id: id,
      finished: finished?,
      updated_at: updated_at,
      html: ApplicationController.new.render_to_string(
        template: "admin/background_jobs/_background_job_state",
        layout: nil,
        locals: {
          background_job: self
        }
      )
    )
  end

  ##
  # Find out whether this job has finished.
  #
  # @return [Boolean] whether this job has finished
  #
  def finished?
    completed_at.present?
  end

  ##
  # Save this BackgroundJob as successful.
  #
  # @param [Hash] results The results (default: {})
  def succeed!(results = {})
    self.completed_at = Time.now
    self.state = :successful
    self.results = results
    self.progress = 1.0

    save
  end

  ##
  # Save this BackgroundJob as failed.
  #
  # @param [String] error_message the error message
  def fail!(error_message)
    self.completed_at = Time.now
    self.state = :failed
    self.error_message = error_message

    save
  end

  ##
  # Save this BackgroundJob as failed.
  #
  # @param [String] message the error message
  def cancel!(message = nil)
    return unless cancellable?

    self.state = :cancelling
    self.error_message = message

    save
  end

  def cancellable?
    scheduled? || running?
  end

  ##
  # Save this BackgroundJob as failed.
  #
  # @param [String] message the error message
  def confirm_cancelled!
    self.completed_at = Time.now
    self.state = :cancelled

    save
  end

  ##
  # Save this BackgroundJob's progress.
  #
  # @param [Integer] current amount done
  # @param [Integer] total amount for completion
  def set_progress(current, total)
    self.progress = current.to_f / total.to_f
    save
  end

  protected

  ##
  # If the job is finished and it has a zipfile referenced in its
  # `results` remove the file upon deletion of the resource.
  def remove_zipfile
    throw :abort unless finished?

    File.delete(results['zipfile']) if results.andand['zipfile']
  rescue => error
    logger.warn(error)
  end
end
