class FormDefinitionDecorator < ApplicationDecorator
  delegate_all

  include Draper::LazyHelpers

  def display_name
    object.name
  end

  def name
    link_to(object.name, admin_form_definition_path(object))
  end

  def status
    if locked_at
      status_tag("locked", class: "ok")
    elsif !object.configuration
      status_tag("unconfigured", class: "warning")
    else
      status_tag("draft")
    end
  end

  def links
    return "" unless configuration

    links = ""
    links << create_form_answer_link if can?(:create, FormAnswer)
    links << " "
    links << open_form_link if object.free_form?
    links.html_safe
  end

  def create_form_answer_link
    link_to("Create Task", new_admin_form_answer_path(form_definition_id: object.id))
  end

  def open_form_link
    link_to("Open Form", new_v1_form_form_answer_path(id, prev: 'close'), target: "_blank")
    
  end

  def current_configuration
    config = object.current_configuration

    return nil if !config
    return config.id if cannot?(:read, config)

    html = ""
    html << link_to(config.id, admin_configuration_path(config))
    html << " ("
    html << link_to("download", download_admin_configuration_path(config))
    html << ")"
    html.html_safe
  end
end
