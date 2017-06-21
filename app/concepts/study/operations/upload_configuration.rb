class Study::UploadConfiguration < Trailblazer::Operation # :nodoc:
  step Model(Study, :find_by)
  step Contract::Build(constant: Study::Contract::UploadConfiguration)
  step Contract::Validate(key: 'study_contract_upload_configuration')
  step :load_config
  step :extract_old_visit_spec
  step :save_configuration
  step :extract_new_visit_spec
  step :extract_required_series_diff
  step :destroy_removed_visits
  step :destroy_removed_required_series
  step :create_added_required_series

  def load_config(options, params:, **)
    options['yaml_config'] = options['contract.default'].file_cache
    options['config'] = YAML.load(options['contract.default'].file_cache)
  end

  def extract_old_visit_spec(options, model:, **)
    visit_type_spec = model.visit_type_spec(version: :current)
    options['old_visit_types'] = visit_type_spec.keys
    options['old_required_series'] = visit_type_spec.transform_values do |spec|
      spec.andand['required_series'].try(:keys) || []
    end
  end

  def save_configuration(_options, yaml_config:, model:, current_user: nil, **)
    model.update_configuration!(yaml_config, user: current_user)
  end

  def extract_new_visit_spec(options, config:, **)
    visit_type_spec = config['visit_types'] || {}
    options['new_visit_types'] = visit_type_spec.keys
    options['new_required_series'] = visit_type_spec.transform_values do |spec|
      spec.andand['required_series'].try(:keys) || []
    end
  end

  def destroy_removed_visits(options, model:, old_visit_types:, new_visit_types:, **)
    deleted_visit_types = (old_visit_types - new_visit_types)
    model.visits.where(visit_type: deleted_visit_types).destroy_all
  end

  def extract_required_series_diff(options, old_required_series:, new_required_series:, **)
    options['required_series_diff'] = (old_required_series.keys | new_required_series.keys).uniq.map do |key|
      [key, [old_required_series[key] || [], new_required_series[key] || []]]
    end.to_h
  end

  def destroy_removed_required_series(_options, model:, required_series_diff:, **)
    required_series_diff.each_pair do |visit_type, (old, new)|
      deleted_required_series = (old - new)
      next if deleted_required_series.empty?
      model.required_series.where(
        visits: { visit_type: visit_type },
        required_series: { name: deleted_required_series }
      ).destroy_all
    end
  end

  def create_added_required_series(_options, model:, required_series_diff:, **)
    required_series_diff.each_pair do |visit_type, (old, new)|
      added_required_series = new - old
      model.visits.where(visit_type: visit_type).each do |visit|
        added_required_series.each do |name|
          visit.required_series.create!(name: name)
        end
      end
    end
  end
end
