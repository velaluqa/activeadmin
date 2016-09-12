module NotificationObservable
  extend ActiveSupport::Concern

  def self.resources
    @resources ||= []
  end

  included do
    NotificationObservable.resources << self

    after_create :notification_observable_create
    after_update :notification_observable_update
    after_destroy :notification_observable_destroy

    def notification_observable_create
      trigger_respective_profiles(:create, self)
    end

    def notification_observable_update
      trigger_respective_profiles(:update, self)
    end

    def notification_observable_destroy
      trigger_respective_profiles(:destroy, self)
    end

    def self.notification_observable?
      true
    end

    private

    def trigger_respective_profiles(action, record)
      triggered_profiles = NotificationProfile.triggered_by(action, record)
      triggered_profiles.each do |profile|
        profile.trigger(action, record)
      end
    end
  end
end

# Per default, models should not be `notification_observable?`.
module ActiveRecord
  class Base
    def self.notification_observable?
      false
    end
  end
end
