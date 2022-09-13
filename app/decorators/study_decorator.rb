class StudyDecorator < ApplicationDecorator
  delegate_all

  include Draper::LazyHelpers

  def name
    link_to(model.name, admin_study_path(model))
  end

  def domino_db_url
    if model.domino_integration_enabled?
      link_to(model.domino_db_url, model.domino_db_url)
    else
      status_tag('Disabled', class: 'warning', label: 'Domino integration not enabled')
    end
  end

  def configuration
    if model.has_configuration?
      status_tag('Available', class: 'ok')
    else
      status_tag('Missing', class: 'error')
    end
  end
  
  def notes_links_base_uri
    link_to(model.notes_links_base_uri, model.notes_links_base_uri) unless model.notes_links_base_uri.nil?
  end

  def configuration_validation
    render 'admin/shared/schema_validation_results', errors: model.validate
  end

  def state
    model.state.to_s.camelize + (model.locked_version.nil? ? '' : " (Version: #{model.locked_version})")
  end

  def select_for_session
    if can? :read, model
      link_to('Select', select_for_session_admin_study_path(model))
    else
      'n/A'
    end
  end
end