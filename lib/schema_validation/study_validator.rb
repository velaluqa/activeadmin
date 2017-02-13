require 'kwalify'
require 'yaml'
require 'dentaku'

module SchemaValidation
  class StudyValidator < Kwalify::Validator
    ## load schema definition
    @@schema = YAML.load_file('lib/schema_validation/study.schema.yml') #HC

    def initialize
      super(@@schema)
    end

    alias_method :original_validate, :validate
    def validate(value)
      @document = value
      original_validate(value)
    end

    def validate_hook(value, rule, path, errors)
      case rule.name
      when 'field_values'
        value.each do |key,value|
          errors << Kwalify::ValidationError.new("Key must be a string, is a #{key.class}", (path.is_a?(String) ? path+'/'+key.to_s : path << key)) unless key.is_a?(String)
        end
      when 'tqc_question'
        errors << Kwalify::ValidationError.new('Only \'dicom\' tQC questions can have \'dicom_tag\' and \'expected\'', path) unless (value['type'] == 'dicom' or (value['dicom_tag'].nil? and value['expected'].nil?))
        errors << Kwalify::ValidationError.new('tQC questions with type \'dicom\' require both \'dicom_tag\' and \'expected\'', path) unless (value['type'] != 'dicom' or (value['dicom_tag'] and value['expected']))
        errors << Kwalify::ValidationError.new('tQC questions with type \'dicom\' require both \'dicom_tag\' and \'expected\'', path) unless (value['type'] != 'dicom' or (value['dicom_tag'] and value['expected']))
        unless(value['expected'].nil? or value['expected'].is_a?(String) or value['expected'].is_a?(Numeric) or value['expected'].is_a?(Array))
          errors << Kwalify::ValidationError.new('\'expected\' must either be a string (formula), number or a list of allowed values', path)
        end
        if(value['expected'].is_a?(String))
          begin
            Dentaku(value['expected'], {:x => 0})
          rescue Exception => e
            errors << Kwalify::ValidationError.new("'expected' with value '#{value['expected']}' contains an invalid formula: #{e.message}", path)
          end
        end
      when 'image_series_property'
        errors << Kwalify::ValidationError.new('Missing \'values\'', path) if(value['type'] == 'select' and value['values'].nil?)
        errors << Kwalify::ValidationError.new('Only type \'select\' can have \'values\'', path) unless (value['type'] == 'select' or value['values'].nil?)
      when 'dicom_tag'
        errors << Kwalify::ValidationError.new("Key must be a string containing a valid DICOM tag in the format 'xxxx,yyyy'", path) unless(value.is_a?(String) and value =~ /\h{4},\h{4}/)
      end
    end
  end
end
