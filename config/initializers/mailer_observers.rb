Rails.application.config.to_prepare do
  require 'observers/notification_mailer_observer'

  NotificationMailer.register_observer(NotificationMailerObserver)
end
