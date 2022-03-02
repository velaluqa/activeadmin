ActiveAdmin.register FormDefinition, name: "Form" do
  menu(parent: 'read', priority: 10)

  permit_params(
    :name,
    :description,
    :id,
    :layout,
    :previous_configuration_id
  )

  controller do
    skip_load_and_authorize_resource only: %i[
      edit_form_schema
      update_form_schema
    ]
  end

  index do
    selectable_column
    column :name do |form|
      link_to form.name, admin_form_definition_path(form)
    end
    column :status do |form|
      if form.locked_at.nil?
        status_tag("draft")
      else
        status_tag("locked", class: "ok")
      end
    end
    column :locked_at
    column "Links" do |form|
      link_to("Open Form", new_v1_form_form_answer_path(form.id), target: "_blank")
    end
    customizable_default_actions(current_ability)
  end

  form do |f|
    f.inputs 'Details' do
      f.input(:name)
      f.input(:description)
    end

    f.actions
  end

  show do |form|
    div class: "side-by-side" do
      panel("Form Preview") do
        if form.current_configuration
          render(
            partial: "form_preview",
            locals: {
              form_layout: form.current_configuration.payload
            }
          )
        else
          div style: "padding: 8px" do
            "Not yet configured"
          end
        end
      end
      attributes_table do
        row :id
        row :name
        row :description
        row 'Current Configuration' do
          if can?(:read, form.current_configuration)
            html = ""
            html << link_to(form.current_configuration_id, admin_configuration_path(form.current_configuration))
            html << " ("
            html << link_to("download", download_admin_configuration_path(form.current_configuration))
            html << ")"
            html.html_safe
          else
            form.current_configuration_id
          end
        end
        row :locked_at
        row :created_at
        row :updated_at
      end
    end
  end

  filter :name
  filter :description

  member_action :edit_form_schema, method: :get do
    @form_definition_id = params[:id]
    @form = FormDefinition.find(params[:id])
    @previous_configuration_id = @form.current_configuration.andand.id
    @form_layout = @form.current_configuration.andand.payload || "{}"
    render "edit_form_schema"
  end

  member_action :update_form_schema, method: :post do
    @form_definition_id = params[:id]
    form = FormDefinition.find(params[:id])
    if params[:layout] == form.current_configuration.andand.payload
      flash[:notice] = "Form layout did not change."
      redirect_to admin_form_definition_path(form)
    else
      configuration = Configuration.create(
        previous_configuration_id: params[:previous_configuration_id],
        configurable: form,
        schema_spec: 'formio_v1',
        payload: params[:layout]
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
    link_to("Edit Form Schema", edit_form_schema_admin_form_definition_path(resource))
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
