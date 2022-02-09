require "canonical_json"

ActiveAdmin.register FormAnswer do
  decorate_with(FormAnswerDecorator)

  menu(parent: 'read', priority: 20)

  includes(:form_definition, :configuration, public_key: :user)

  actions(:index, :show)

  filter :form_definition
  filter :configuration_id, as: :string
  filter :is_test_data
  filter :is_obsolete
  filter :signed_at
  filter :submitted_at

  controller do
    helper :application
  end

  index do
    selectable_column

    column :form_definition
    column :status
    column "Signatures", :signature_status
    column "User", :user_public_key, sortable: "users.name"
    column :submitted_at

    customizable_default_actions(current_ability)
  end

  show do |form_answer|
    div class: "side-by-side" do
      panel("Form Answers") do
        div class: "form_answers_data" do
          render_react_component(
            "admin_form_answers_preview",
            form_answer: form_answer.attributes,
            configuration: form_answer.configuration.attributes
          )
        end
      end

      attributes_table do
        row :form_definition
        row :configuration
        row :submitted_at
        row :signature_status
        row :user_public_key
      end
    end
  end

  action_item :audit_trail, only: :show, if: -> { can?(:read, Version) } do
    url = admin_versions_path(
      audit_trail_view_type: 'form_answer',
      audit_trail_view_id: resource.id
    )
    link_to('Audit Trail', url)
  end
end
