require "reform/form/coercion"

module Study::Contract
  class UploadConfiguration < Reform::Form
    attr_reader(:parsed_config)

    feature Coercion

    property :id
    property :file, virtual: true
    property :file_cache, virtual: true, prepopulate: -> { file.try(:tempfile).try(:read) }
    property :force, virtual: true, type: Types::Params::Bool

    validates :file, presence: true, if: -> { file_cache.blank? }
    validate :json_schema
    validate :affected_visits, if: -> { force != true }
    validate :affected_required_series, if: -> { force != true }

    def forcable?
      error_fields = errors.messages.select { |_, errors| errors.present? }.keys
      return false if error_fields.empty?
      error_fields == [:force]
    end

    def yaml_config
      file_cache
    end

    def file_cache
      file_cache = file.try(:tempfile).try(:read)
      return @fields['file_cache'] if file_cache.blank?
      @fields['file_cache'] = file_cache
    end

    private

    def json_schema
      @parsed_config = YAML.load(file_cache)
      validator = SchemaValidation::StudyValidator.new
      json_errors = validator.validate(parsed_config)
      json_errors.each do |json_error|
        errors.add(:file, json_error.to_s)
      end
    rescue
      errors.add(:file, 'could not be parsed')
    end

    def affected_visits
      return if parsed_config.blank?
      return if deleted_visit_types.empty?
      errors.add(:force, "removed visit types will be deleted from all visits:<br> #{deleted_visit_types.join(', <br>')}")
    end

    def affected_required_series
      return if parsed_config.blank?
      return if deleted_required_series.empty?
      errors.add(:force, "removed required series will be deleted from all visits:<br> #{deleted_required_series.join(', <br>')}")
    end

    def old_visit_types
      study.visit_types(version: :current)
    end

    def new_visit_types
      parsed_config.andand['visit_types'].try(:keys) || []
    end

    def deleted_visit_types
      old_visit_types - new_visit_types
    end

    def old_required_series
      study.visit_type_spec(version: :current).flat_map do |visit_type, spec|
        next if deleted_visit_types.include?(visit_type)
        spec.andand['required_series'].try(:keys).map do |name|
          "#{visit_type}/#{name}"
        end
      end.compact
    end

    def new_required_series
      new_visit_type_spec.flat_map do |visit_type, spec|
        spec.andand['required_series'].try(:keys).map do |name|
          "#{visit_type}/#{name}"
        end
      end.compact
    end

    def deleted_required_series
      old_required_series - new_required_series
    end

    def new_visit_type_spec
      parsed_config.andand['visit_types'] || {}
    end

    def study
      model
    end
  end
end
