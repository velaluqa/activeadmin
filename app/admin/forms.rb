# -*- coding: utf-8 -*-
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
      row :download_configuration do
        if form.raw_configuration.nil?
          status_tag('Missing', :error)
        else
          link_to 'Download Configuration', download_configuration_admin_form_path(form)
        end
      end
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

  member_action :download_configuration do
    @form = Form.find(params[:id])

    send_file @form.config_file_path unless @form.raw_configuration.nil?
  end
  member_action :upload_config, :method => :post do
    @form = Form.find(params[:id])

    # TODO: create git commit
    if(params[:form].nil? or params[:form][:file].nil? or params[:form][:file].tempfile.nil?)
      flash[:error] = "You must specify a configuration file to upload"
      redirect_to({:action => :show})
    else
      FileUtils.copy(params[:form][:file].tempfile, @form.config_file_path)
        
      redirect_to({:action => :show}, :notice => "Configuration successfully uploaded")
    end
  end
  member_action :upload_config_form, :method => :get do
    @form = Form.find(params[:id])
    
    @page_title = "Upload new configuration"
    render 'admin/forms/upload_config', :locals => { :url => upload_config_admin_form_path}
  end
  action_item :only => :show do
    link_to 'Upload configuration', upload_config_form_admin_form_path(resource)
  end
end
