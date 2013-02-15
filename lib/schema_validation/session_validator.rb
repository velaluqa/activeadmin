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
      when 'root'
        limit_previous_results = value['limit_previous_results']
        types = value['types']
        if(not limit_previous_results.nil? and limit_previous_results.is_a?(Array) and types.is_a?(Hash))
          limit_previous_results.reject {|case_type| types.include?(case_type)}.each do |unknown_case_type|
            errors << Kwalify::ValidationError.new("Case type #{unknown_case_type} is referenced in 'limit_previous_results', but not defined", path)
          end
        end
      end
    end
  end
end
