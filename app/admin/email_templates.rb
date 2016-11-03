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
end
