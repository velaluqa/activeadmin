module NotificationObservable
  class Filter
    class Schema
      class Relation
        attr_reader :klass, :definitions, :options

        def initialize(klass, options = {})
          @options = {
            filters: %i(matches relations),
          }.merge(options)
          @options[:filters] = @options[:filters] - [:changes]
          @klass = klass
          @definitions = {}
        end

        def schema
          merge_definitions(model)
          {
            title: "Related #{klass}",
            type: 'object',
            required: [klass.to_s.underscore],
            properties: {
              klass.to_s.underscore => {
                '$ref' => model.definition_ref
              }
            }
          }
        end

        protected

        def model
          @model ||= Model.new(klass, options)
        end

        def merge_definitions(model)
          @definitions[model.definition_ref] ||= model.definition
          @definitions.merge!(model.definitions)
        end
      end
    end
  end
end
