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
class BackgroundJob < ActiveRecord::Base
  belongs_to :user

  before_destroy :remove_zipfile

  scope :completed, -> { where(completed: true) }
  scope :running, -> { where(completed: false) }

  scope :granted_for, -> (options = {}) {
    user = options[:user] || raise("Missing 'user' option")
    return all if user.is_root_user?
    where(user_id: options[:user].id)
  }

  scope :searchable, -> { select(<<SELECT) }
NULL AS study_id,
background_jobs.name AS text,
background_jobs.id AS result_id,
'BackgroundJob' AS result_type
SELECT

  ##
  # Find out whether this job has finished.
  #
  # @return [Boolean] whether this job has finished
  #
  # TODO: Refactor to use `completed_at` as indicator for completed jobs.
  def finished?
    completed
  end

  ##
  # Find out whether this job has failed.
  #
  # @return [Boolean] whether this job has failed
  def failed?
    completed && !successful
  end

  ##
  # Save this BackgroundJob as successful.
  #
  # @param [Hash] results The results (default: {})
  def finish_successfully(results = {})
    finish

    self.successful = true
    self.results = results

    save
  end

  ##
  # Save this BackgroundJob as failed.
  #
  # @param [String] error_message the error message
  def fail(error_message)
    finish

    self.successful = false
    self.error_message = error_message

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
  # Update this job as completed.
  #
  # TODO: Refactor to use `completed_at` as sole completion
  # indicator.
  #
  # @param [Boolean] save whether to save the model (default: false)
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
