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
    @user = user
    @profile = profile
    @notifications = notifications
    mail(
      to: @user.email,
      subject: @profile.title
    )
  end

  # Sends an email with only one notification.
  #
  # @param [Notification] notification The single notification to send.
  #
  # @return [Mail] The mail that may be delivered
  def instant_notification_email(notification)
    @user = notification.user
    @profile = notification.notification_profile
    @notifications = [notification]
    @notification = notification
    mail(
      to: @user.email,
      subject: @profile.title
    )
  end
end
