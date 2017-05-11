require 'kwalify'
require 'yaml'
require 'dentaku'

module SchemaValidation
  class StudyValidator < Kwalify::Validator
    ## load schema definition
    @@schema = YAML.load_file('lib/schema_validation/study.schema.yml') # HC

    attr_reader :validation_cache

    def initialize
      super(@@schema)
    end

    alias_method :original_validate, :validate
    def validate(value)
      @validation_cache = {}
      @document = value
      original_validate(value)
    end

    def validate_hook(value, rule, path, errors)
      case rule.name
      when 'field_values'
        value.each do |key, _value|
          errors << Kwalify::ValidationError.new("Key must be a string, is a #{key.class}", (path.is_a?(String) ? path + '/' + key.to_s : path << key)) unless key.is_a?(String)
        end
      when 'tqc_question'
        errors << Kwalify::ValidationError.new('Only \'dicom\' tQC questions can have \'dicom_tag\' and \'expected\'', path) unless value['type'] == 'dicom' || (value['dicom_tag'].nil? && value['expected'].nil?)
        errors << Kwalify::ValidationError.new('tQC questions with type \'dicom\' require both \'dicom_tag\' and \'expected\'', path) unless value['type'] != 'dicom' || (value['dicom_tag'] && value['expected'])
        errors << Kwalify::ValidationError.new('tQC questions with type \'dicom\' require both \'dicom_tag\' and \'expected\'', path) unless value['type'] != 'dicom' || (value['dicom_tag'] && value['expected'])
        unless value['expected'].nil? || value['expected'].is_a?(String) || value['expected'].is_a?(Numeric) || value['expected'].is_a?(Array)
          errors << Kwalify::ValidationError.new('\'expected\' must either be a string (formula), number or a list of allowed values', path)
        end
        if value['expected'].is_a?(String)
          begin
            Dentaku(value['expected'], x: 0)
          rescue Exception => e
            errors << Kwalify::ValidationError.new("'expected' with value '#{value['expected']}' contains an invalid formula: #{e.message}", path)
          end
        end
      when 'image_series_property'
        errors << Kwalify::ValidationError.new('Missing \'values\'', path) if value['type'] == 'select' && value['values'].nil?
        errors << Kwalify::ValidationError.new('Only type \'select\' can have \'values\'', path) unless value['type'] == 'select' || value['values'].nil?
      when 'dicom_tag'
        errors << Kwalify::ValidationError.new("Key must be a string containing a valid DICOM tag in the format 'xxxx,yyyy'", path) unless value.is_a?(String) && value =~ /\h{4},\h{4}/
      when 'visit_template'
        if value['only_on_create_patient'] && value['hide_on_create_patient']
          errors << Kwalify::ValidationError.new('Choose either `only_on_create_patient` or `hide_on_create_patient`', path)
        end
        if value['create_patient_default']
          if validation_cache[:create_patient_default].present?
            errors << Kwalify::ValidationError.new("Already defined `create_patient_default` for visit template in #{validation_cache[:create_patient_default]}", path)
          else
            validation_cache[:create_patient_default] = path
          end
        end
        if value['create_patient_enforce']
          if validation_cache[:create_patient_enforce].present?
            errors << Kwalify::ValidationError.new("Already defined `create_patient_enforce` for visit template in #{validation_cache[:create_patient_enforce]}", path)
          else
            validation_cache[:create_patient_enforce] = path
          end
        end
      when 'visit'
        unless @document['visit_types'].andand.key?(value['type'])
          errors << Kwalify::ValidationError.new('Visit type not found in map of /visit_types', path)
        end
      end
    end
  end
end
