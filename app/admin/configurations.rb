ActiveAdmin.register Configuration do
  menu(false)

  actions :index, :show

  show do |configuration|
    div class: "side-by-side" do
      panel("Data") do
        div class: "configuration_data" do
          render_react_component(
            "admin_configurations_preview",
            configuration: configuration.attributes,
            previous_configuration: configuration.previous_configuration.andand.attributes || {}
          )
        end
      end

      attributes_table do
        row :id
        row :previous_configuration
        row :configurable_type
        row :configurable
        row :schema_spec
        row :created_at
        row :updated_at
      end
    end
  end

  member_action :download, method: :get do
    configuration = Configuration.find(params[:id])
    send_data(
      configuration.payload,
      filename: "#{configuration.configurable.name}_#{configuration.id}.json",
      disposition: 'attachment'
    )
  end

  action_item :audit_trail, only: :show, if: -> { can?(:read, Version) } do
    url = admin_versions_path(
      audit_trail_view_type: 'configuration',
      audit_trail_view_id: resource.id
    )
    link_to('Audit Trail', url)
  end
end
