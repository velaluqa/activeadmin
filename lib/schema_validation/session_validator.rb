require 'kwalify'
require 'yaml'

module SchemaValidation
  class SessionValidator < Kwalify::Validator
    ## load schema definition
    @@schema = YAML.load_file('lib/schema_validation/session.schema.yml') #HC

    def initialize
      super(@@schema)
    end

    def validate_hook(value, rule, path, errors)
      case rule.name
      when 'previous_results'
        errors << Kwalify::ValidationError.new("Must contain either 'default_table' or 'table'", path) unless ((not value['default_table'].nil?) ^ (not value['table'].nil?))
        errors << Kwalify::ValidationError.new("'merge_columns' can only be used with 'table', not 'default_table'", path) unless (value['default_table'].nil? or value['merge_columns'].nil?)
      when 'previous_results_table_row'
        unless ((not value['group'].nil?) ^ (not value['row'].nil?) ^ (not value['repeatable'].nil?))
          errors << Kwalify::ValidationError.new("Must contain exactly one of 'group', 'row' or 'repeatable'", path)
        else
          errors << Kwalify::ValidationError.new("Only 'row' rows can not contain 'value' or 'values'", path) unless ((value['value'].nil? and value['values'].nil?) or not value['row'].nil?)
          errors << Kwalify::ValidationError.new("'row' must have either 'value' or 'values'", path) unless (value['row'].nil? or (value['value'].nil? ^ value['values'].nil?))
        end
      when 'previous_results_table_repeatable_row'
        errors << Kwalify::ValidationError.new("'row' must have either 'value' or 'values'", path) unless (value['value'].nil? ^ value['values'].nil?)
      end
    end
  end
end
