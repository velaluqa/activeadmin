module NotificationObservable
  class Filter
    class Schema
      class Model
        attr_reader :klass, :definitions, :options

        def initialize(klass, options = {})
          @options = {
            filters: %i(matches changes relations),
            ignore_relations: [Notification, NotificationProfile,
                               Version, ActsAsTaggableOn::Taggable,
                               ActsAsTaggableOn::Tagger, ActsAsTaggableOn::Tagging]
          }.merge(options)
          @options[:ignore_relations] = @options[:ignore_relations] + [klass]
          @klass = klass
          @definitions = {}
        end

        def definition
          { oneOf: attributes + relations }
        end

        def definition_ref
          "#/definitions/#{definition_key}"
        end

        def definition_key
          "model_#{@klass.to_s.underscore}"
        end

        protected

        def attributes
          @klass.columns.map do |column|
            Attribute.new(@klass, column).schema(options)
          end
        end

        def relations
          @klass._reflections.values.map do |reflection|
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
