module NotificationObservable
  class Filter
    class Schema
      class Relation
        attr_reader :reflection, :definitions, :options

        def initialize(reflection, options = {})
          @options = options.merge(
            filters: %i(equality relations),
            is_relation: true
          )
          @reflection = reflection
          @definitions = {}
        end

        def schema
          merge_definitions(model)
          {
            title: "Related #{reflection.name.to_s.camelize}",
            type: 'object',
            required: [reflection.name.to_s],
            properties: {
              reflection.name.to_s => {
                '$ref' => model.definition_ref
              }
            }
          }
        end

        protected

        def model
          @model ||= Model.new(reflection.klass, options)
        end

        def merge_definitions(model)
          @definitions[model.definition_key] ||= model.definition
          @definitions.merge!(model.definitions)
        end
      end
    end
  end
end
