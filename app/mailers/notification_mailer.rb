class NotificationMailer < ActionMailer::Base
  helper ApplicationHelper

  layout 'notification_mailer'

  # Sends an email with many throttled notifications.
  #
  # @param [User] user Recipient of the e-Mail
  # @param [NotificationProfile] profile The profile specifying
  #   additional options
  # @param [Array[Notifications]] notifications The set of throttled
  #   notifications
  #
  # @return [Mail] The mail that may be delivered
  def throttled_notification_email(user, profile, notifications)
    headers 'X-Notification-IDs' => notifications.map(&:id).join(';')
    mail(
      to: user.email,
      subject: profile.title,
      body: render_message(user, profile, notifications),
      content_type: 'text/html'
    )
  end

  # Sends an email with only one notification.
  #
  # @param [Notification] notification The single notification to send.
  #
  # @return [Mail] The mail that may be delivered
  def instant_notification_email(notification)
    headers 'X-Notification-IDs' => notification.id.to_s
    mail(
      to: notification.user.email,
      subject: notification.notification_profile.title,
      body: render_message(
        notification.user,
        notification.notification_profile,
        [notification]),
      content_type: 'text/html'
    )
  end

  private

  def render_message(user, profile, notifications)
    EmailTemplateRenderer.new(
      profile.email_template,
      user: user,
      notification_profile: profile,
      notifications: notifications
    ).render
  end
end
