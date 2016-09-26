module NotificationObservable
  class Filter
    class Schema
      class Attribute
        FILTERS = %i(matches changes).freeze

        def initialize(model, column)
          @model = model
          @column = column
        end

        def schema(options)
          {
            title: @column.name,
            type: 'object',
            required: [@column.name],
            properties: {
              @column.name => {
                oneOf: filters(options)
              }
            }
          }
        end

        def filters(options = {})
          (FILTERS & options[:filters]).map do |filter|
            send("#{filter}_filter")
          end.flatten
        end

        def matches_filter
          {
            title: 'matches',
            type: 'object',
            required: ['matches'],
            properties: {
              matches: validation
            }
          }
        end

        def changes_filter
          [
            changes_bool_filter,
            changes_from_filter,
            changes_to_filter,
            changes_from_to_filter
          ]
        end

        def changes_bool_filter
          {
            title: 'changes',
            type: 'object',
            required: ['changes'],
            properties: {
              changes: {
                type: 'boolean'
              }
            }
          }
        end

        def changes_from_to_filter
          {
            title: 'changes (from => to)',
            type: 'object',
            required: ['changes'],
            properties: {
              changes: {
                type: 'object',
                required: ['from', 'to'],
                properties: {
                  from: validation,
                  to: validation
                }
              }
            }
          }
        end

        def changes_from_filter
          {
            title: 'changes (from => any value)',
            type: 'object',
            required: ['changes'],
            properties: {
              changes: {
                type: 'object',
                required: ['from'],
                properties: {
                  from: validation
                }
              }
            }
          }
        end

        def changes_to_filter
          {
            title: 'changes (any value => to)',
            type: 'object',
            required: ['changes'],
            properties: {
              changes: {
                type: 'object',
                required: ['to'],
                properties: {
                  to: validation
                }
              }
            }
          }
        end

        def validation
          options = []
          options << { title: 'NULL', type: 'null' } if @column.null
          options << value_validation
          { oneOf: options }
        end

        def value_validation
          schema = { title: 'value' }.merge(type_defaults)
          @model.validators_on(@column.name).each do |validator|
            schema.merge!(from_validator(validator))
          end
          schema
        end

        def type_defaults
          case  @column.type
          when :integer, :bigint then { type: 'integer' }
          when :float, :decimal  then { type: 'number' }
          when :datetime         then { type: 'string', format: 'datetime' }
          when :date             then { type: 'string', format: 'date' }
          when :time             then { type: 'string', format: 'time' }
          when :binary, :boolean then { type: 'boolean', format: 'checkbox' }
          else { type: 'string' }
          end
        end

        def from_validator(validator)
          case validator
          when ActiveModel::Validations::NumericalityValidator
            from_numericality_validator(validator)
          when ActiveModel::Validations::LengthValidator
            from_length_validator(validator)
          when ActiveModel::Validations::FormatValidator
            from_format_validator(validator)
          when ActiveModel::Validations::InclusionValidator
            from_inclusion_validator(validator)
          else {}
          end
        end

        def from_numericality_validator(validator)
          validation = {}
          validator.options.each_pair do |key, value|
            validation.merge!(from_numericality_validator_options(key, value))
          end
          validation
        end

        def from_numericality_validator_options(key, value)
          case key
          when :less_than_or_equal_to then { maximum: value }
          when :less_than then { maximum: value, exclusiveMaximum: true }
          when :greater_than_or_equal_to then { minimum: value }
          when :greater_than then { minimum: value, exclusiveMinimum: true }
          end
        end

        def from_length_validator(validator)
          validation = {}
          validator.options.each_pair do |key, value|
            validation.merge!(from_length_validator_options(key, value))
          end
          validation
        end

        def from_length_validator_options(key, value)
          case key
          when :minimum then { minLength: value }
          when :maximum then { maxLength: value }
          when :is then { minLength: value, maxLength: value}
          end
        end

        def from_inclusion_validator(validator)
          { enum: validator.options[:in].map(&:to_s) }
        end

        def from_format_validator(validator)
          { pattern: validator.options[:with] }
        end
      end
    end
  end
end
