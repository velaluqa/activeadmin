require 'redcarpet_inline_renderer'

module ApplicationHelper
  # used by the mongoid history tracker _changeset partial
  # needs to be defined here to be found
  def mongoid_history_tracker_diff(values)
    # we remove the first line of YAML output, since it only contains metadata (and we don't need it for the diff, it only looks confusing)
    old = values[:from].to_yaml(canonical: false, indentation: 9).lines.to_a[1..-1].join.gsub(/!ruby\/hash:ActiveSupport::HashWithIndifferentAccess/, '')
    new = values[:to].to_yaml(canonical: false, indentation: 9).lines.to_a[1..-1].join.gsub(/!ruby\/hash:ActiveSupport::HashWithIndifferentAccess/, '')
    Diffy::Diff.new(old, new).to_s(:html).html_safe
  end

  def admin_url_for(model)
    method = "admin_#{model.class.to_s.underscore}_url"
    Rails.application.routes.url_helpers.send(method, model)
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
end
