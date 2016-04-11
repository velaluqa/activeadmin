class BackgroundJob
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: Integer

  field :completed, type: Boolean, default: false
  field :progress, type: Float, default: 0.0
  field :name, type: String
  field :completed_at, type: Time

  field :successful, type: Boolean
  field :error_message, type: String

  field :results, type: Hash

  index user_id: 1
  index completed: 1

  scope :completed, -> { where(completed: true) }
  scope :running, -> { where(completed: false) }

  before_destroy do
    return false unless finished?

    begin
      File.delete(results['zipfile']) if results.andand['zipfile']
    rescue => error
      logger.warn(error)
    end
  end

  def user
    User.find(read_attribute(:user_id))
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def user=(user)
    write_attribute(:user_id, user.id)
  end

  def finished?
    completed
  end

  def failed?
    finished? && !successful
  end

  def finish_successfully(results)
    finish

    self.successful = true
    self.results = results

    save
  end

  def fail(error_message)
    finish

    self.successful = false
    self.error_message = error_message

    save
  end

  def set_progress(current, total)
    self.progress = current.to_f / total.to_f
    save
  end

  protected

  def finish(save = false)
    self.completed = true
    self.completed_at = Time.now

    self.save if save
  end
end
