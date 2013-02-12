# -*- coding: utf-8 -*-
ActiveAdmin.register Form do

  scope :all, :default => true
  scope :draft
  scope :final

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
      if(form.has_configuration?)
        status_tag('Available', :ok)
      else
        status_tag('Missing', :error)
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
      row :download_current_configuration do
        if form.has_configuration?
          link_to 'Download Current Configuration', download_current_configuration_admin_form_path(form)
        else
          status_tag('Missing', :error)
        end
      end
      row :current_configuration do
        config = form.current_configuration if form.has_configuration?

        if not form.has_configuration?
          status_tag('Missing', :error)       
        elsif config.nil?
          status_tag('Invalid', :warning)
        else
          CodeRay.scan(JSON::pretty_generate(config), :json).div(:css => :class).html_safe
        end
      end
      unless form.locked_version.nil?
        row :download_locked_configuration do
          link_to 'Download Locked Configuration', download_locked_configuration_admin_form_path(form)
        end
        row :locked_configuration do
          config = form.locked_configuration

          if config.nil?
            status_tag('Invalid', :warning)
          else
            CodeRay.scan(JSON::pretty_generate(config), :json).div(:css => :class).html_safe
          end
        end
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :session
      f.input :name
      f.input :description
    end

    f.buttons
  end

  member_action :download_current_configuration do
    @form = Form.find(params[:id])

    data = GitConfigRepository.new.data_at_version(@form.relative_config_file_path, nil)
    send_data data, :filename => "form_#{@form.id}_current.yml" unless data.nil?
  end
  member_action :download_locked_configuration do
    @form = Form.find(params[:id])

    data = GitConfigRepository.new.data_at_version(@form.relative_config_file_path, @form.locked_version)
    send_data data, :filename => "form_#{@form.id}_#{@form.locked_version}.yml" unless data.nil?
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
    return if @form.session.nil?

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
    return if @form.session.nil?

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
    next if resource.session.nil? # template forms can not be finalised
    next unless can? :manage, resource

    if resource.state == :draft
      link_to 'Lock', lock_admin_form_path(resource)
    elsif resource.state == :final
      link_to 'Unlock', unlock_admin_form_path(resource) if resource.session.state == :building
    end
  end
end
