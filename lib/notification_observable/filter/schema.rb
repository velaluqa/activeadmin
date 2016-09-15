require 'notification_observable/filter/schema/attribute'
require 'notification_observable/filter/schema/model'
require 'notification_observable/filter/schema/relation'

module NotificationObservable
  class Filter
    class Schema
      def initialize(klass)
        @klass = klass
      end

      def schema
        model = Model.new(@klass)
        # The order is important. The method `model.definition`
        # populates the `model.definitions` Hash.
        definition = model.definition

        {
          definitions: model.definitions,
          type: 'array',
          items: {
            title: 'Filter',
            type: 'array',
            uniqueItems: true,
            minItems: 1,
            items: {
              title: 'Condition',
              oneOf: definition
            }
          }
        }
      end
    end
  end
end
