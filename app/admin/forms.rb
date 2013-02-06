# -*- coding: utf-8 -*-
ActiveAdmin.register Form do
  index do
    selectable_column
    column :name do |form|
      link_to form.name, admin_form_path(form)
    end
    column :description
    column :state do |form|
      form.state.to_s.camelize
    end
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
      row :description
      row :state do
        form.state.to_s.camelize + (form.locked_version.nil? ? '' : " (Version: #{form.locked_version})")
      end
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
      repo = GitConfigRepository.new
      repo.update_config_file(@form.relative_config_file_path, params[:form][:file].tempfile, current_user, "New configuration file for form #{@form.id}")
        
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

  member_action :lock do
    @form = Form.find(params[:id])
    return if @form.nil?

    if(cannot? :manage, @form)
      flash[:error] = 'You are not authorized to lock this form!'
      redirect_to :action => :show
      return
    end

    @form.state = :final
    @form.locked_version = GitConfigRepository.new.current_version
    @form.save

    redirect_to({:action => :show}, :notice => 'Form locked')
  end
  member_action :unlock do
    @form = Form.find(params[:id])
    return if @form.nil?

    if(cannot? :manage, @form)
      flash[:error] = 'You are not authorized to unlock this form!'
      redirect_to :action => :show
      return
    end

    @form.state = :draft
    @form.locked_version = nil
    @form.save

    redirect_to({:action => :show}, :notice => 'Form unlocked')
  end
  
  action_item :only => :show do
    if resource.state == :draft
      link_to 'Lock', lock_admin_form_path(resource)
    elsif resource.state == :final
      link_to 'Unlock', unlock_admin_form_path(resource)      
    end
  end
end
