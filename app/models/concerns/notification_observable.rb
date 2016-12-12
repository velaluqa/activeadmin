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
      TriggerNotificationProfiles.perform_async(:create, self.class, id, YAML.dump(previous_changes))
    end

    def notification_observable_update
      TriggerNotificationProfiles.perform_async(:update, self.class, id, YAML.dump(previous_changes))
    end

    def notification_observable_destroy
      TriggerNotificationProfiles.perform_async(:destroy, self.class, id, YAML.dump({}.with_indifferent_access))
    end

    def self.notification_observable?
      true
    end
  end
end

# Per default, models should not be `notification_observable?`.
module ActiveRecord
  class Base # :nodoc:
    def self.notification_observable?
      false
    end
  end
end
