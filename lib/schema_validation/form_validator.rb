require 'kwalify'
require 'yaml'

module SchemaValidation
  class FormValidator < Kwalify::Validator
    ## load schema definition
    @@schema = YAML.load_file('lib/schema_validation/form.schema.yml') #HC

    def initialize
      super(@@schema)
    end

    # def validate_hook(value, rule, path, errors)
    #   case rule.name
    #   end
    # end
  end
end
