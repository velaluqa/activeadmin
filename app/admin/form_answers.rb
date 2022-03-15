require "canonical_json"

ActiveAdmin.register FormAnswer do
  decorate_with(FormAnswerDecorator)

  config.sort_order = 'submitted_at_desc'

  menu(parent: 'read', priority: 20)

  includes(:form_definition, :configuration, :user, public_key: :user)

  scope :all, default: true
  scope :draft
  scope :published
  scope :signed

  filter :form_session
  filter :form_definition
  filter :form_answer_resources_resource_type, label: "Associated Resource Type", as: :select, collection: (FormDefinition::RESOURCE_TYPES - ["any"]).sort
  filter :user, as: :select
  filter :is_test_data
  filter :is_obsolete
  filter :signed_at
  filter :status
  filter :submitted_at

  permit_params(
    :form_answer,
    :form_definition_id,
    :user_id,
    :study_id,
    :form_session_id,
    :configuration_id,
    :resource_identifier,
    :configuration_id,
    :answers_json,
    form_answer_resources_attributes: [:id, :resource_identifier, :_destroy]
  )

  controller do
    helper :application
  end

  index do
    selectable_column

    column :form_session, sortable: "form_sessions.name"
    column "#", :sequence_number
    column :form_definition, sortable: "form_definitions.name"
    column :resources
    column :status
    column "User", :user, sortable: "users.name"
    column :published_at
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

      div do
        attributes_table do
          row :user unless form_answer.validates_user_id == "none"
          row :form_session unless form_answer.validates_form_session_id == "none"
          row :study unless form_answer.validates_study_id == "none"
          row :form_definition
          row :status
          row :errors unless form_answer.valid?
          row :submitted_at
          row :signature_status
          row :configuration
        end

        if form_answer.validates_resource_id != "none"
          panel "Associated Resources" do
            table_for form_answer.form_answer_resources do
              column :resource
            end
          end
        end
      end
    end
  end

  form do |f|
    form_definition_id = params[:form_definition_id] || params[:form_answer].andand[:form_definition_id]
    form_definition = form_definition_id ? FormDefinition.find(form_definition_id) : object.form_definition
    object.form_definition = form_definition if form_definition
    object.configuration ||= form_definition.configuration if form_definition
    object.form_answer_resources << FormAnswerResource.new if object.validates_resource_id == "required" && object.form_answer_resources.length == 0

    div class: "side-by-side" do
      div do
      f.inputs 'Details' do
        text_node javascript_include_tag("form_answers/form")
        f.input(:form_definition)

        unless object.validates_study_id == "none"
          f.input(
            :study,
            as: :select,
            collection: Study.all,
            include_blank: object.validates_study_id == "optional",
            input_html: {
              "data-placeholder": "Choose a study",
              "data-allow-clear": object.validates_study_id == "optional"
            }
          )
        end

        unless object.validates_form_session_id == "none"
          f.input(
            :form_session,
            as: :select,
            collection: FormSession.all,
            include_blank: object.validates_form_session_id == "optional",
            input_html: {
              "data-placeholder": "Choose a session",
              "data-allow-clear": object.validates_form_session_id == "optional"
            }
          )
        end

        unless object.validates_user_id == "none"
          f.input(
            :user,
            as: :select,
            collection: User.all,
            include_blank: true,
            input_html: {
              "data-placeholder": "Assign a user",
              "data-allow-clear": object.validates_user_id == "optional"
            }
          )
        end
      end
      unless object.validates_resource_id == "none"
        f.inputs 'Associated Resources' do
          f.has_many(
            :form_answer_resources,
            allow_destroy: true,
            heading: "Resources",
            new_record: "Add Resource",
            remove_record: "Remove Resource"
          ) do |far|
            collection = []
            collection.push([far.object.resource.to_s, far.object.resource_identifier]) if far.object.resource
            far.input(
              :resource_identifier,
              as: :select,
              label: "Resource",
              collection: collection,
              input_html: {
                class: "select2-record-search",
                'data-models' => object.validates_resource_type == "any" ? "Study,Center,Patient" : object.validates_resource_type,
                'data-placeholder' => 'Select Resource',
                'data-allow-clear' => false
              }
            )
          end
        end
      end
      end
      f.inputs "Draft Form Answers" do
        if form_definition.nil?
          text_node "Please select a form on the left-hand side."
        elsif form_answer && form_definition.current_configuration.nil?
          text_node "Form Definition is not yet configured. Please make sure that you selected the correct form or that the form has a valid form configuration."
        else
          f.input(:configuration_id, as: :hidden)
          f.input(:answers_json, as: :hidden, style: "display: none;")
          render(
            partial: "form",
            locals: {
              form_layout: JSON.dump(object.layout)
            }
          )
        end

      end
    end

    f.actions
  end

  action_item :audit_trail, only: :show, if: -> { can?(:read, Version) } do
    url = admin_versions_path(
      audit_trail_view_type: 'form_answer',
      audit_trail_view_id: resource.id
    )
    link_to('Audit Trail', url)
  end

  action_item :edit, only: :show do
    link_to "Publish", publish_admin_form_answer_path(resource) unless resource.published?
  end

  member_action :publish, only: [:index] do
    answer = FormAnswer.find(params[:id])
    answer.published_at = DateTime.now
    answer.save!

    redirect_back(fallback_location: admin_form_answers_path)
  end
end
