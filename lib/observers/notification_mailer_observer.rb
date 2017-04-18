class NotificationMailerObserver
  def self.delivered_email(message)
    ids = message.header['X-Notification-IDs'].to_s.split(';').map(&:to_i)
    now = DateTime.now
    Notification.where(id: ids).each do |notification|
      notification.email_sent_at = now
      notification.save!
    end
  end
end
