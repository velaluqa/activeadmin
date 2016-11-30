require 'redcarpet'

module MarkdownHandler # :nodoc:
  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template)
    compiled_source = erb.call(template)
    "Redcarpet::Markdown.new( Redcarpet::Render::HTML.new(with_toc_data: false), no_intra_emphasis: true, tables: true, fenced_code_blocks: true, autolink: true, strikethrough: true).render(begin;#{compiled_source};end)"
  end
end

ActionView::Template.register_template_handler :md, MarkdownHandler
