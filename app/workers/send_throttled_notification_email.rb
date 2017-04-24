class SendThrottledNotificationEmail
  include Sidekiq::Worker

  sidekiq_options(queue: :notifications, retry: 5)

  # Invokes NotificationMailer within a Sidekiq job.
  #
  # @param [Integer] user_id The recipients user id
  # @param [Integer] profile_id The triggered profile
  # @param [Array<Integer>] notification_ids The notifications to send.
  def perform(user_id, profile_id, notification_ids)
    user = User.find_by(id: user_id)
    profile = NotificationProfile.find_by(id: profile_id)
    notifications =
      Notification.joins(:version).order('"versions"."study_id" ASC').where(id: notification_ids)

    NotificationMailer
      .throttled_notification_email(user, profile, notifications)
      .deliver_now
    Notification.where(id: notification_ids).update_all(email_sent_at: DateTime.now)
  end
end
