class TriggerNotificationProfiles
  include Sidekiq::Worker

  sidekiq_options(queue: :notifications, retry: 5)

  def perform(version_id)
    version = Version.find(version_id)
    triggered_profiles(version).each do |profile|
      profile.trigger(version)
    end
  end

  def triggered_profiles(version)
    NotificationProfile.triggered_by(
      version.event,
      version.item_type,
      version.item || version.reify,
      version.object_changes
    )
  end
end
