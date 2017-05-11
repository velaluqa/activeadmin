require 'kwalify'
require 'yaml'

module SchemaValidation
  class SessionValidator < Kwalify::Validator
    ## load schema definition
    @@schema = YAML.load_file('lib/schema_validation/session.schema.yml') # HC

    def initialize
      super(@@schema)
    end

    def validate_hook(value, rule, path, errors)
      case rule.name
      when 'previous_results'
        errors << Kwalify::ValidationError.new("Must contain either 'default_table' or 'table'", path) unless (!value['default_table'].nil?) ^ !value['table'].nil?
        errors << Kwalify::ValidationError.new("'merge_columns' can only be used with 'table', not 'default_table'", path) unless value['default_table'].nil? || value['merge_columns'].nil?
      when 'previous_results_table_row'
        if (!value['group'].nil?) ^ !value['row'].nil? ^ !value['repeatable'].nil?
          errors << Kwalify::ValidationError.new("Only 'row' rows can not contain 'value' or 'values'", path) unless (value['value'].nil? && value['values'].nil?) || !value['row'].nil?
          errors << Kwalify::ValidationError.new("'row' must have either 'value' or 'values'", path) unless value['row'].nil? || (value['value'].nil? ^ value['values'].nil?)
        else
          errors << Kwalify::ValidationError.new("Must contain exactly one of 'group', 'row' or 'repeatable'", path)
        end
      when 'previous_results_table_repeatable_row'
        errors << Kwalify::ValidationError.new("'row' must have either 'value' or 'values'", path) unless value['value'].nil? ^ value['values'].nil?
      when 'case_type'
        errors << Kwalify::ValidationError.new("Must have either 'screen_layout' or 'dont_use_viewer: true'", path) unless (!value['screen_layout'].nil?) ^ value['dont_use_viewer']
      when 'case_type_screen_layout'
        errors << Kwalify::ValidationError.new("When 'strict' is set, 'sidebar' can't be true.", path) if value['strict'] && value['sidebar']
        errors << Kwalify::ValidationError.new("When 'strict' is set, 'passive' can't be true.", path) if value['strict'] && value['passive']
        errors << Kwalify::ValidationError.new("'passive_annotations' requires 'passive' to be 'true'.", path) if value['passive_annotations'] && !(value['passive'])
      when 'case_type_screen_layout_series'
        errors << Kwalify::ValidationError.new("'display' can't contain any series that is not contained in 'import'. Offending series: #{(value['display'] - value['import']).join(',')}.", path) unless (value['display'] - value['import']).empty?
        errors << Kwalify::ValidationError.new("'roi' can't contain any series that is not contained in 'import'. Offending series: #{(value['roi'] - value['import']).join(',')}.", path) unless (value['roi'] - value['import']).empty?
      end
    end
  end
end
