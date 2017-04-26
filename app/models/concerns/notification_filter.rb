module NotificationFilter
  extend ActiveSupport::Concern

  included do
    def notification_attribute_filter?(attribute, filter)
      self.class.notification_attribute_filters[attribute.to_sym].andand[filter.to_sym].is_a?(Proc)
    end

    def match_notification_attribute_filter(attribute, filter, old, new)
      return false unless notification_attribute_filter?(attribute, filter)
      filter = self.class.notification_attribute_filters[attribute.to_sym].andand[filter.to_sym]
      filter.call(old, new)
    end
  end

  class_methods do
    def notification_attribute_filters
      @notification_attribute_filters ||= {}
    end

    def notification_attribute_filter(attribute, filter, &block)
      notification_attribute_filters[attribute.to_sym] ||= {}
      notification_attribute_filters[attribute.to_sym][filter.to_sym] = block
    end
  end
end
