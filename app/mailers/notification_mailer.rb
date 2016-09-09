class NotificationMailer < ActionMailer::Base
  helper ApplicationHelper

  layout 'notification_mailer'

  def throttled_notification_email(user, profile, notifications)
    @user = user
    @profile = profile
    @notifications = notifications
    mail(
      to: @user.email,
      subject: @profile.title
    )
  end
end
