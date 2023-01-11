module Study::Operation
  class UploadConfiguration < Trailblazer::Operation # :nodoc:
    step Model(Study, :find_by)
    step Contract::Build(constant: Study::Contract::UploadConfiguration)
    step Contract::Validate(key: 'study_contract_upload_configuration')
    step :load_config
    step :save_configuration

    def load_config(context, params:, **)
      context['yaml_config'] = context['contract.default'].file_cache
      context['config'] = YAML.load(context['contract.default'].file_cache)
    end

    def save_configuration(_context, yaml_config:, model:, current_user: nil, **)
      model.update_configuration!(yaml_config, user: current_user)
    end
  end
end
