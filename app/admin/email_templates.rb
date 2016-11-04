require 'email_template_renderer'

ActiveAdmin.register EmailTemplate do
  config.filters = false

  permit_params(:name, :email_type, :template)

  form do |f|
    f.inputs 'Details' do
      f.input :name
      f.input :email_type, as: :select, collection: %w(NotificationProfile), input_html: { class: 'initialize-select2' }
      f.input :template, as: :hidden
    end
    f.render partial: 'editor'
    f.actions
  end

  collection_action :preview, method: :get do
    begin
      subject = ActiveRecord::Base.find_by_ref(params.fetch(:subject))
      authorize!(:read, subject)
      preview = EmailTemplateRenderer.render_preview(
        type: params.fetch(:type),
        subject: subject,
        user: current_user,
        template: params.fetch(:template)
      )
      render json: { preview: preview }, status: :ok
    rescue EmailTemplateRenderer::CompilationError => e
      render json: { type: 'compilation', error: e.to_h }, status: :unprocessable_entity
    rescue ActiveAdmin::AccessDenied => e
      render json: { error: 'Access Denied' }, status: :forbidden
    rescue => e
      Airbrake.notify(e)
      render json: { type: 'system', error: e.to_s }, status: :internal_server_error
    end
  end
end
