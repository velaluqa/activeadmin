Liquid::Template.error_mode = :warn

class EmailTemplateRenderer # :nodoc:
  class Error < StandardError # :nodoc:
    def initialize(errors)
      @errors = errors
      super("#{errors.count} template error(s)")
    end

    def errors
      @errors.map do |error|
        {
          message: error.message,
          line_number: error.line_number,
          backtrace: error.backtrace
        }
      end
    end
  end

  attr_accessor :template, :scope

  def initialize(template, scope = {})
    @template = template
    @scope = scope.deep_stringify_keys
  end

  def render
    tpl = "<p>#{@template.template.gsub(/(\n\n|\r\n\r\n|\n\r\n\r)/, '</p><p>').strip}</p>"
    liquid = Liquid::Template.parse(
      tpl,
      error_mode: :strict,
      line_numbers: true
    )
    result = liquid.render(scope, strict_variables: true).gsub('<p></p>', '')
    raise EmailTemplateRenderer::Error, liquid.errors unless liquid.errors.blank?
    ActionController::Base.new.render_to_string(text: result, layout: 'email_template')
  rescue Liquid::Error => e
    raise EmailTemplateRenderer::Error, [e]
  end

  class << self
    def render_preview(options = {})
      template = EmailTemplate.new(
        email_type: options.fetch(:type),
        template: options.fetch(:template)
      )
      EmailTemplateRenderer.new(template, preview_locals(options)).render
    end

    private

    def preview_locals(options = {})
      type = options.fetch(:type)
      case type
      when 'NotificationProfile' then notification_profile_template_locals(options)
      else raise "EmailTemplate type '#{type}' not supported"
      end
    end

    def notification_profile_template_locals(options = {})
      user = options.fetch(:user)
      notification = Notification.new(
        triggering_action: 'create',
        user: user,
        resource: options.fetch(:subject),
        version: options.fetch(:subject).try(:versions).try(:last)
      )
      {
        user: user,
        notifications: [notification]
      }
    end
  end
end
