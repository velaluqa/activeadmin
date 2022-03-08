class FormDefinitionDecorator < ApplicationDecorator
  delegate_all

  include Draper::LazyHelpers

  def name
    link_to(object.name, admin_form_definition_path(object))
  end

  def status
    if locked_at
      status_tag("locked", class: "ok")
    else
      status_tag("draft")
    end
  end

  def links
    link_to("Open Form", new_v1_form_form_answer_path(id), target: "_blank")
  end

  def current_configuration
    config = object.current_configuration

    return config.id if cannot?(:read, config)

    html = ""
    html << link_to(config.id, admin_configuration_path(config))
    html << " ("
    html << link_to("download", download_admin_configuration_path(config))
    html << ")"
    html.html_safe
  end
end
