# The `ERICA` module serves simple helper methods to keep the code as
# clean as possible.
class ERICA
  class << self
    def remote?
      Rails.application.config.is_erica_remote
    end

    def store?
      !Rails.application.config.is_erica_remote
    end

    def data_path
      Rails.root + Pathname.new(Rails.application.config.data_directory)
    end

    def form_config_path
      Rails.root + Pathname.new(Rails.application.config.form_configs_directory)
    end

    def session_config_path
      Rails.root + Pathname.new(Rails.application.config.session_configs_directory)
    end

    def study_config_path
      Rails.root + Pathname.new(Rails.application.config.study_configs_directory)
    end

    def image_storage_path
      Rails.root + Pathname.new(Rails.application.config.image_storage_root)
    end

    def config_paths
      [form_config_path, session_config_path, study_config_path]
    end

    def site_title
      Rails.application.config.try(:erica).andand['site_title'] || 'ERICA'
    end

    def site_title_image
      Rails.application.config.try(:erica).andand['site_title']
    end

    def narrow_site_title_image
      Rails.application.config.try(:erica).andand['narrow_site_title_image']
    end

    def narrow_site_title
      Rails.application.config.try(:erica).andand['narrow_site_title']
    end

    def default_dashboard_configuration
      {
        general: {
          rows: [
            {
              widgets: [
                {
                  type: 'overview',
                  params: {
                    columns: 'all'
                  }
                }
              ]
            }
          ]
        }
      }.with_indifferent_access
    end

    def maximum_email_throttling_delay
      Rails.application.config.maximum_email_throttling_delay
    end
  end
end
