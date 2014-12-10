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

  scope :completed, where(completed: true)
  scope :running, where(completed: false)

  before_destroy do
    return false unless self.finished?

    if(self.results and self.results['zipfile'])
      begin
        File.delete(self.results['zipfile'])
      rescue => e
        logger.warn e
      end
    end
  end

  def user
    begin
      return User.find(read_attribute(:user_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def user=(user)
    write_attribute(:user_id, user.id)
  end

  def finished?
    self.completed
  end
  def failed?
    self.finished? and self.successful == false
  end

  def finish_successfully(results)
    self.finish

    self.successful = true
    self.results = results

    self.save
  end
  def fail(error_message)
    self.finish

    self.successful = false
    self.error_message = error_message

    self.save
  end
  def set_progress(current, total)
    self.progress = current.to_f/total.to_f
    self.save
  end

  protected

  def finish(save = false)
    self.completed = true
    self.completed_at = Time.now

    self.save if save
  end
end
