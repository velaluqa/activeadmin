require 'notification_observable/filter'
require 'notification_observable/filter/schema'

module NotificationObservable
  extend ActiveSupport::Concern

  def self.resources
    @resources ||= []
  end

  def self.register(model)
    resources << model
    resources.uniq!
  end

  included do
    NotificationObservable.register(self)

    after_commit(:notification_observable_create, on: :create)
    after_commit(:notification_observable_update, on: :update)
    after_commit(:notification_observable_destroy, on: :destroy)

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
      TriggerNotificationProfiles.perform_async(action, record.class, record.id, YAML.dump(record.changes))
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
