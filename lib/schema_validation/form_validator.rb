require 'kwalify'
require 'yaml'

module SchemaValidation
  class FormValidator < Kwalify::Validator
    ## load schema definition
    @@schema = YAML.load_file('lib/schema_validation/form.schema.yml') #HC

    def initialize
      super(@@schema)
    end

    def validate_hook(value, rule, path, errors)
      case rule.name
      when 'field'
        if not value['id'].nil?
          errors << Kwalify::ValidationError.new('Missing \'type\'', path) if value['type'].nil?
          errors << Kwalify::ValidationError.new('Missing \'label\'', path) if (value['label'].nil? and not value['type'] == 'section')

          errors << Kwalify::ValidationError.new('Missing \'fixed_value\'', path) if(value['type'] == 'fixed' and value['fixed_value'].nil?)

          errors << Kwalify::ValidationError.new('Missing \'roi_values\'', path) if(value['type'] == 'roi' and value['roi_values'].nil?)
          errors << Kwalify::ValidationError.new('Missing \'values\'', path) if(['select', 'select_multiple'].include?(value['type']) and value['values'].nil?)
          errors << Kwalify::ValidationError.new('Only types \'select\',\'select_multiple\' and \'roi\' can have \'values\'', path) unless (['select', 'select_multiple', 'roi'].include?(value['type']) or value['values'].nil?)
          errors << Kwalify::ValidationError.new('Only \'number\' fields can have use \'dot_as_separator\'', path) unless(value['dot_as_separator'].nil? or value['type'] == 'number')
          errors << Kwalify::ValidationError.new('Only \'number\' fields can have use \'integer_only\'', path) unless(value['integer_only'].nil? or value['type'] == 'number')
          errors << Kwalify::ValidationError.new('Only \'calculated\' fields can have a \'calculation_function\'', path) unless(value['calculation_function'].nil? or value['type'] == 'calculated')
          errors << Kwalify::ValidationError.new('Only \'calculated\' fields can specify \'store_calculated_value\'', path) unless(value['store_calculated_value'].nil? or value['type'] == 'calculated')
          errors << Kwalify::ValidationError.new('Fields of type \'calculated\' must specify a \'calculation_function\'', path) if(value['type'] == 'calculated' and value['calculation_function'].nil?)
          errors << Kwalify::ValidationError.new('Only \'group\' fields can specify \'belongs_to_repeatable\'', path) if(value['type'] != 'group' and value['belongs_to_repeatable'])
          unless value['selected_option'].nil?
            case value['type']
            when 'select', 'roi'
              errors << Kwalify::ValidationError.new('For \'select\' and \'roi\' fields, \'selected_option\' must be a string', path) unless value['selected_option'].is_a?(String)
            when 'select_multiple'
              errors << Kwalify::ValidationError.new('For \'select_multiple\' fields, \'selected_option\' must be a list', path) unless value['selected_option'].is_a?(Array)
            else
              errors << Kwalify::ValidationError.new('Only \'select\',\'select_multiple\' and \'roi\' fields can have a \'selected_option\'', path)
            end
          end
        elsif not value['include'].nil?
          # no custom checks for includes yet, 'repeat' is not required
        elsif value['type'] == 'section'
          # no custom checks for sections, we just need this so sections can exist without an id
        else
          errors << Kwalify::ValidationError.new('This is neither a field (missing \'id\') nor an include (missing \'include\')', path)
        end
      when 'validation'
        unless value.size == 2
          errors << Kwalify::ValidationError.new('A validation must have a message and exactly one validation constraint', path)
        end
      when 'field_values'
        value.each do |key,value|
          errors << Kwalify::ValidationError.new("Key must be a string, is a #{key.class}", (path.is_a?(String) ? path+'/'+key.to_s : path << key)) unless key.is_a?(String)
        end
      end
    end
  end
end
