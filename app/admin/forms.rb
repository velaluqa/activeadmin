ActiveAdmin.register Form do
  index do
    selectable_column
    column :name do |form|
      link_to form.name, admin_form_path(form)
    end
    column 'Version', :form_version
    column :description
    column :session
    column :configuration do |form|
      if(form.raw_configuration.nil?)
        status_tag('Missing', :error)
      else
        status_tag('Available', :ok)
      end
    end
  end

  show do |form|
    attributes_table do
      row :name
      row :form_version
      row :description
      row :session
      row :configuration do
        config = form.raw_configuration
        if config.nil?
          nil
        else
          CodeRay.scan(JSON::pretty_generate(config), :json).div(:css => :class).html_safe
        end
      end
    end
  end
end
