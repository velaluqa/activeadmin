class TriggerNotificationProfiles
  include Sidekiq::Worker

  sidekiq_options(queue: :notifications, retry: 5)

  def perform(action, record_klass, record_id, changes)
    changes = YAML.load(changes)
    record = record_klass.constantize.find(record_id)
    triggered_profiles =
      NotificationProfile.triggered_by(action, record, changes)
    triggered_profiles.each do |profile|
      profile.trigger(action.to_sym, record)
    end
  end
end
