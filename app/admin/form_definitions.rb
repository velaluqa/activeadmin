ActiveAdmin.register FormDefinition, name: "Form" do
  decorate_with(FormDefinitionDecorator)

  menu(parent: 'read', priority: 10)

  permit_params(
    :name,
    :description,
    :id,
    :layout,
    :previous_configuration_id,
    :validates_user_id,
    :validates_study_id,
    :validates_form_session_id,
    :validates_resource_id,
    :validates_resource_type,
    :listing,
    :sequence_scope
  )

  controller do
    skip_load_and_authorize_resource only: %i[
      edit_form_schema
      update_form_schema
    ]
  end

  index do
    selectable_column
    column :name
    column :status
    column :locked_at
    column "Links", :links
    customizable_default_actions(current_ability)
  end

  form do |f|
    f.inputs 'Details' do
      f.input(:name)
      f.input(:description)
    end
    f.inputs 'Form Answer Settings' do
      f.input(
        :validates_user_id,
        as: :select,
        include_blank: false,
        collection: FormDefinition::VALIDATION_VALUES
      )
      f.input(
        :validates_study_id,
        as: :select,
        include_blank: false,
        collection: FormDefinition::VALIDATION_VALUES
      )
      f.input(
        :validates_form_session_id,
        as: :select,
        include_blank: false,
        collection: FormDefinition::VALIDATION_VALUES
      )
      f.input(
        :validates_resource_id,
        as: :select,
        include_blank: false,
        collection: FormDefinition::VALIDATION_VALUES
      )
      f.input(
        :validates_resource_type,
        as: :select,
        include_blank: false,
        collection: FormDefinition::RESOURCE_TYPES
      )
    end
    f.actions
  end

  show do |form|
    div class: "side-by-side" do
      panel("Form Preview") do
        if form.layout.empty?
          div style: "padding: 8px" do
            "Not yet configured"
          end
        else
          render(
            partial: "form_preview",
            locals: {
              form_layout: JSON.dump(form.layout)
            }
          )
        end
      end

      div do
        attributes_table do
          row :id
          row :name
          row :description
          row :current_configuration
          row :locked_at
          row :created_at
          row :updated_at
        end
        attributes_table title: "Form Answer Settings" do
          row :validates_user_id
          row :validates_study_id
          row :validates_form_session_id
          row :validates_resource_id
          row :validates_resource_type
        end
      end
    end
  end

  filter :name
  filter :description

  member_action :edit_form_schema, method: :get do
    # TODO: Authorize for edit, form_definition
    @form_definition_id = params[:id]
    @form = FormDefinition.find(params[:id])
    @previous_configuration_id = @form.current_configuration.andand.id
    @form_layout = JSON.dump(@form.current_configuration.andand.data.andand["layout"]) || "{}"
    render "edit_form_schema"
  end

  member_action :update_form_schema, method: :post do
    # TODO: Move into trailblazer operation
    # TODO: Authorize edit FormDefinition
    @form_definition_id = params[:id]
    form = FormDefinition.find(params[:id])
    if params[:layout] == form.current_configuration.andand.payload
      flash[:notice] = "Form layout did not change."
      redirect_to admin_form_definition_path(form)
    else
      previous_configuration = Configuration.where(id: params[:previous_configuration_id]).first
      data = {}
      data = previous_configuration.data if previous_configuration
      data["layout"] = JSON.parse(params[:layout])

      configuration = Configuration.create(
        previous_configuration_id: params[:previous_configuration_id],
        configurable: form,
        schema_spec: 'formio_v1',
        payload: JSON.dump(data)
      )

      form.current_configuration_id = configuration.id
      success = form.save
      if success
        flash[:notice] = "Form layout updated"
        redirect_to admin_form_definition_path(form)
      else
        ap form.errors
        flash[:notice] = "Could not save form layout"
        render "edit_form_schema"
      end
    end
  end

  action_item :edit, only: :show do
    link_to("Form Layout Editor", edit_form_schema_admin_form_definition_path(resource))
  end

  action_item :upload, only: %i[edit_form_schema update_form_schema] do
    input("upload-file", type:"file", id: "upload-file", accept: ".json", style: "display: none;")
    label("Upload JSON", for: "upload-file", style: "cursor: pointer; font-weight: normal;")
  end

  action_item :save, only: %i[edit_form_schema update_form_schema] do
    link_to("Save Form Schema", "#", id: "save_form_definition")
  end

  action_item :audit_trail, only: :show, if: -> { can?(:read, Version) } do
    url = admin_versions_path(
      audit_trail_view_type: 'form_definition',
      audit_trail_view_id: resource.id
    )
    link_to('Audit Trail', url)
  end
end
