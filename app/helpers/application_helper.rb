require 'redcarpet_inline_renderer'

module ApplicationHelper
  def admin_url_for(model)
    method = "admin_#{model.class.to_s.underscore}_url"
    Rails.application.routes.url_helpers.send(method, model)
  end

  def autocomplete_tags_path(model, options = {})
    method = "autocomplete_tags_admin_#{model.class.to_s.underscore}_path"
    Rails.application.routes.url_helpers.send(method, model, options)
  end

  def markdown(str)
    @renderer ||= Redcarpet::Markdown.new(
      RedcarpetInlineRenderer,
      no_intra_emphasis: true,
      tables: false,
      fenced_code_blocks: false,
      autolink: true,
      strikethrough: true
    )
    @renderer.render(str).html_safe
  end

  # TODO: Remove the need for `arbre`
  def arbre(&block)
    puts "Deprecated: Try to avoid abre blocks in default views"
    Arbre::Context.new(&block).to_s
  end

  def status_tag(status, options = {})
    ActiveAdmin::Views::StatusTag.new.status_tag(status, options)
  end

  def render_react_component(pack_name, options = {})
    component_props =
      options
        .except(:layout)
        .deep_transform_keys { |key| key.to_s.camelize(:lower) }

    render(
      partial: "admin/general/react_pack_component",
      locals: {
        pack_name: pack_name,
        component_props: component_props
      }
    )
  end
end
