module NotificationObservable
  class Filter
    class Schema
      def for_model(model, options = {})
        options = {
          subschemas: %i(matches changes relations)
        }.merge(options)
        # attributes => changes / matches
        # relation => for_model(related model, [:match, :relation],
        # depth + 1)

        filters = []
        model.columns.each do |column|
          filters << for_attribute(column, options)
        end

        {
          oneOf: filters
        }
      end

      protected

      def for_attribute(column, options = {})
        {
          title: column.name,
          type: 'object',
          properties: {
            column.name => {
              oneOf: attribute_filters(column, options)
            }
          }
        }
      end

      def attribute_filters(column, options)
        filters = []
        filters.push(matches_attribute_filter(column)) if options[:subschemas].andand.include?(:matches)
        filters.push(changes_attribute_filter(column)) if options[:subschemas].andand.include?(:changes)
        filters
      end

      def matches_attribute_filter(column)
        {
          type: 'object',
          properties: {
            matches: attribute_type(column)
          }
        }
      end

      def changes_attribute_filter(column)
        {
          type: 'object',
          properties: {
            changes: {
              type: 'object',
              properties: {
                from: attribute_type(column),
                to: attribute_type(column)
              }
            }
          }
        }
      end

      def attribute_type(column)
        case column.sql_type
        when 'integer' then attribute_integer_type
        when 'string' then attribute_string_type
        else attribute_string_type
        end
      end

      def attribute_integer_type
        {
          type: 'number'
        }
      end

      def attribute_string_type
        {
          type: 'string'
        }
      end
    end
  end
end
