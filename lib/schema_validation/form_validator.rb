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
          errors << Kwalify::ValidationError.new('Missing \'label\'', path) if value['label'].nil?
          errors << Kwalify::ValidationError.new('Missing \'fixed_value\'', path) if(value['type'] == 'fixed' and value['fixed_value'].nil?)
          errors << Kwalify::ValidationError.new('Missing \'values\'', path) if(['select', 'select_multiple', 'roi'].include?(value['type']) and value['values'].nil?)
        elsif not value['include'].nil?
          # no custom checks for includes yet, 'repeat' is not required
        else
          errors << Kwalify::ValidationError.new('This is neither a field (missing \'id\') nor an include (missing \'include\')', path)
        end
      when 'validation'
        unless value.size == 2
          errors << Kwalify::ValidationError.new('A validation must have a message and exactly one validation constraint', path)
        end
      end
    end
  end
end
