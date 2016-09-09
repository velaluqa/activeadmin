# coding: utf-8
class SendThrottledNotificationEmails
  include Sidekiq::Worker

  sidekiq_options(queue: :notifications, retry: 5)

  # Looks up all notification profiles and users for which unsent
  # notifications exist. If they match the given throttling delay,
  # they trigger a new email for the detected notification profile and
  # user.
  #
  # @param [Integer, String] throttle Either a throttling String like
  #   `hourly`, `daily` (as defined in Email::THROTTLING_DELAYS) or a
  #   number describing the throttling_delay in seconds.
  def perform(throttle)
    throttle = Email.ensure_throttling_delay(throttle)
    NotificationProfile.all.each do |profile|
      users = profile.recipients_with_pending(throttled: throttle)
      users.each { |user| send_throttled_email(user, profile) }
    end
  end

  private

  # Creates a new job, to send an e-Mail with notifications.
  #
  # @param [User] user The recipient
  # @param [NotificationProfile] profile The profile which defines the
  #   e-mail template.
  def send_throttled_email(user, profile)
    notifications = Notification.pending.of(profile).for(user)

    SendThrottledNotificationEmail
      .perform_async(user.id, profile.id, notifications.pluck(:id))
  end
end
