require 'kwalify'
require 'yaml'

module SchemaValidation
  class ExportValidator < Kwalify::Validator
    ## load schema definition
    @@schema = YAML.load_file('lib/schema_validation/export.schema.yml') # HC

    def initialize
      super(@@schema)
    end

    # def validate_hook(value, rule, path, errors)
    # end
  end
end
