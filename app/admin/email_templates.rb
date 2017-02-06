require 'email_template_renderer'

ActiveAdmin.register EmailTemplate do
  menu(
    parent: 'notifications',
    priority: 20
  )

  config.filters = false

  permit_params(:name, :email_type, :template)

  index do
    selectable_column
    column :name
    column :email_type
    column :created_at
    column :updated_at
    customizable_default_actions(current_ability)
  end

  show do |template|
    attributes_table do
      row :id
      row :name
      row :email_type
      row :created_at
      row :updated_at
    end
    render partial: 'show_preview', locals: { template: template }
  end

  form do |f|
    f.inputs 'Details' do
      f.input :name
      f.input :email_type, as: :select, collection: %w(NotificationProfile), input_html: { class: 'initialize-select2', 'data-placeholder': 'Select e-mail type' }
      f.input :template, as: :hidden
    end
    f.render partial: 'editor'
    f.actions
  end

  collection_action :preview, method: :get do
    begin
      subject = ActiveRecord::Base.find_by_ref(params.fetch(:subject))
      authorize!(:read, subject)
      result = EmailTemplateRenderer.render_preview(
        type: params.fetch(:type),
        subject: subject,
        user: current_user,
        template: params.fetch(:template)
      )
      render json: { result: result }, status: :ok
    rescue EmailTemplateRenderer::Error => e
      render json: { type: 'compilation', errors: e.errors }, status: :unprocessable_entity
    rescue ActiveAdmin::AccessDenied => e
      render json: { error: 'Access Denied' }, status: :forbidden
    rescue => e
      Airbrake.notify(e)
      render json: { type: 'system', error: e.to_s }, status: :internal_server_error
    end
  end
end
