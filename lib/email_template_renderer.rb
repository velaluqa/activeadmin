require 'ostruct'

class EmailTemplateRenderer # :nodoc:
  class CompilationError < StandardError # :nodoc:
    attr_reader :line_number

    def initialize(msg, line_number)
      super(msg)
      @line_number = line_number
    end

    def to_h
      {
        message: message,
        line_number: line_number
      }
    end
  end

  attr_accessor :template, :scope

  def initialize(template, scope = {})
    @template = template
    @scope = scope
  end

  def render
    ERB.new(template.template).result(template_binding)
  rescue => e
    extract_compilation_error(e)
  end

  private

  def extract_compilation_error(error)
    line_number = error.backtrace.detect do |line|
      erb = line.match(/^\(erb\):(?<line_number>\d+)(|:in `(.+)')$/) and break erb[:line_number]
    end
    raise CompilationError.new(error.message, line_number) if line_number
    raise error # otherwise just re-raise the error
  end

  def template_binding
    OpenStruct.new(scope).instance_eval { binding }
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
      notification = Notification.new(
        user: options.fetch(:user),
        resource: options.fetch(:subject),
        version: options.fetch(:subject).try(:versions).try(:last)
      )
      { notifications: [notification] }
    end
  end
end
