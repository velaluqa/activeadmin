class SendInstantNotificationEmail
  include Sidekiq::Worker

  sidekiq_options(queue: :notifications, retry: 5)

  # Invokes NotificationMailer within a Sidekiq job.
  #
  # @param [Integer] notification_id The notification id
  def perform(notification_id)
    notification = Notification.find_by(id: notification_id)
    NotificationMailer
      .instant_notification_email(notification)
      .deliver_now
  end
end
