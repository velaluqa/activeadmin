module NotificationObservable
  class Filter
    class Schema
      class Model
        attr_reader :klass, :definitions, :options

        def initialize(klass, options = {})
          @options = {
            filters: %i[equality changes custom relations],
            ignore_relations: [Notification, NotificationProfile,
                               Version, ActsAsTaggableOn::Taggable,
                               ActsAsTaggableOn::Tagger, ActsAsTaggableOn::Tagging],
            is_relation: false
          }.merge(options)
          @options[:ignore_relations] = @options[:ignore_relations] + [klass]
          @klass = klass
          @definitions = {}
        end

        def definition
          { oneOf: relation_existance + attributes + relations }
        end

        def definition_ref
          "#/definitions/#{definition_key}"
        end

        def definition_key
          "model_#{@klass.to_s.underscore}"
        end

        protected

        def relation_existance
          return [] unless options[:is_relation]
          [{ title: 'Record exists?', type: 'boolean' }]
        end

        def attributes
          @klass.columns.map do |column|
            Attribute.new(@klass, column).schema(options)
          end
        end

        def relations
          @klass._reflections.values.map do |reflection|
            # Polymorphic relations do not have a `@klass`, but need
            # to be checked before calling `reflection.klass`, because
            # the `klass` method would try to find the class constant,
            # which mustn't be defined for polymorphic relations.
            next if reflection.polymorphic?
            # Through relations do not have a `@klass`.
            next unless reflection.andand.klass
            next if options[:ignore_relations].include?(reflection.klass)
            relation = Relation.new(reflection, options)
            schema = relation.schema
            @definitions.merge!(relation.definitions)
            schema
          end.compact
        end
      end
    end
  end
end
