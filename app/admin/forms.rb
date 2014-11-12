# -*- coding: utf-8 -*-
require 'aa_customizable_default_actions'
require 'git_config_repository'

ActiveAdmin.register Form do

  config.clear_action_items! # get rid of the default action items, since we have to handle 'edit' and 'delete' on a case-by-case basis

  scope :all, :default => true
  scope :draft
  scope :final

  menu false if Rails.application.config.is_erica_remote
  config.comments = false

  controller do
    load_and_authorize_resource :except => :index
    skip_load_and_authorize_resource :only => [:download_current_configuration, :download_locked_configuration, :download_configuration_at_version, :download_current_custom_validators, :download_locked_custom_validators, :download_custom_validators_at_version, :copy, :copy_form]

    def max_csv_records
      1_000_000
    end

    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end

    def update
      if params[:form][:session_id].nil? or params[:form][:session_id].empty?
        unless Ability.can_manage_template_forms?(current_user)
          flash[:error] = 'You are not authorized to manage form templates!'
          redirect_to :action => :show
          return
        end
      else
        authorize! :manage, Session.find(params[:form][:session_id])
      end
      update!
    end
    def create
      if params[:form][:session_id].nil? or params[:form][:session_id].empty?
        unless Ability.can_manage_template_forms?(current_user)
          flash[:error] = 'You are not authorized to manage form templates!'
          redirect_to :action => :show
          return
        end
      else
        authorize! :manage, Session.find(params[:form][:session_id])
      end
      create!
    end
  end

  index do
    selectable_column
    column :name, :sortable => :name do |form|
      link_to form.name, admin_form_path(form)
    end
    column :description
    column :state, :sortable => :state do |form|
      form.state.to_s.camelize
    end
    column :session, :sortable => :session_id
    column :configuration do |form|
      if(form.has_configuration?)
        status_tag('Available', :ok)
      else
        status_tag('Missing', :error)
      end
    end

    customizable_default_actions do |form|
      except = []
      except << :destroy unless can? :destroy, form
      except << :edit unless can? :edit, form
      
      except
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
      if form.has_configuration?
        row :configuration_validation do        
          render 'admin/shared/schema_validation_results', :errors => form.validate
        end
      end
      row :configuration do
        current = {}
        if form.has_configuration?
          current_config = form.current_configuration 
          if current_config.nil?
            current[:configuration] = :invalid
          else
            current[:configuration] = CodeRay.scan(JSON::pretty_generate(current_config), :json).div(:css => :class).html_safe
          end
          
          current[:download_link] = download_current_configuration_admin_form_path(form)
        end
        locked = nil
        unless form.locked_version.nil?
          locked = {}
    
          locked_config = form.locked_configuration
          if locked_config.nil?
            locked[:configuration] = :invalid
          else
            locked[:configuration] = CodeRay.scan(JSON::pretty_generate(locked_config), :json).div(:css => :class).html_safe
          end
          
          locked[:download_link] = download_locked_configuration_admin_form_path(form)
        end

        render 'admin/shared/config_table', :current => current, :locked => locked
      end
      row :custom_validators do
        current_components = form.current_components
        locked_components = form.locked_components

        current = {}
        if not (current_components.nil? or current_components[:validators].nil? or current_components[:validators].empty?)
          current[:configuration] = CodeRay.scan(current_components[:validators][0], :javascript).div(:css => :class).html_safe
          current[:download_link] = download_current_custom_validators_admin_form_path(form)
        end          

        locked = nil
        unless form.locked_version.nil?
          locked = {}
    
          if not (locked_components.nil? or locked_components[:validators].nil? or locked_components[:validators].empty?)
            locked[:configuration] = CodeRay.scan(locked_components[:validators][0], :javascript).div(:css => :class).html_safe
          end
          
          locked[:download_link] = download_locked_custom_validators_admin_form_path(form)
        end

        render 'admin/shared/config_table', :current => current, :locked => locked
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :session, :collection => Session.accessible_by(current_ability).order('id ASC'), :include_blank => Ability.can_manage_template_forms?(current_user)
      f.input :name
      f.input :description
    end

    f.buttons
  end

  # filters
  filter :session, :collection => Proc.new { Session.accessible_by(current_ability).order('id ASC') }
  filter :name
  filter :description
  filter :state, :as => :check_boxes, :collection => Form::STATE_SYMS.each_with_index.map {|state, i| [state, i]}

  # copied from activeadmin/lib/active_admin/resource/action_items.rb#add_default_action_items
  action_item :except => [:new, :show] do
    if controller.action_methods.include?('new')
      link_to(I18n.t('active_admin.new_model', :model => active_admin_config.resource_label), new_resource_path)
    end
  end
  action_item :only => :show do
    if controller.action_methods.include?('edit') and can? :edit, resource
      link_to(I18n.t('active_admin.edit_model', :model => active_admin_config.resource_label), edit_resource_path(resource))
    end
  end
  action_item :only => :show do
    if controller.action_methods.include?('destroy') and can? :destroy, resource
      link_to(I18n.t('active_admin.delete_model', :model => active_admin_config.resource_label),
              resource_path(resource),
              :method => :delete, :data => {:confirm => I18n.t('active_admin.delete_confirmation')})
    end
  end 

  member_action :download_current_configuration do
    @form = Form.find(params[:id])
    authorize! :read, @form

    data = GitConfigRepository.new.data_at_version(@form.relative_config_file_path, nil)
    if(data.nil?)
      flash[:error] = 'No configuration exist for this version.'
      redirect_to :back
    else
      send_data data, :filename => "form_#{@form.id}_current.yml"
    end
  end
  member_action :download_locked_configuration do
    @form = Form.find(params[:id])
    authorize! :read, @form

    data = GitConfigRepository.new.data_at_version(@form.relative_config_file_path, @form.locked_version)
    if(data.nil?)
      flash[:error] = 'No configuration exist for this version.'
      redirect_to :back
    else
      send_data data, :filename => "form_#{@form.id}_#{@form.locked_version}.yml"
    end
  end
  member_action :download_configuration_at_version do
    @form = Form.find(params[:id])
    authorize! :read, @form

    data = GitConfigRepository.new.data_at_version(@form.relative_config_file_path, params[:version])
    if(data.nil?)
      flash[:error] = 'No configuration exist for this version.'
      redirect_to :back
    else
      send_data data, :filename => "form_#{@form.id}_#{params[:version]}.yml"
    end
  end
  member_action :download_current_custom_validators do
    @form = Form.find(params[:id])
    authorize! :read, @form

    data = GitConfigRepository.new.data_at_version(@form.relative_validator_file_path, nil)
    if(data.nil?)
      flash[:error] = 'No custom validators exist for this version.'
      redirect_to :back
    else
      send_data data, :filename => "form_#{@form.id}_current.js"
    end
  end
  member_action :download_locked_custom_validators do
    @form = Form.find(params[:id])
    authorize! :read, @form

    data = GitConfigRepository.new.data_at_version(@form.relative_validator_file_path, @form.locked_version)
    if(data.nil?)
      flash[:error] = 'No custom validators exist for this version.'
      redirect_to :back
    else
      send_data data, :filename => "form_#{@form.id}_#{@form.locked_version}.js"
    end
  end
  member_action :download_custom_validators_at_version do
    @form = Form.find(params[:id])
    authorize! :read, @form

    data = GitConfigRepository.new.data_at_version(@form.relative_validator_file_path, params[:version])
    if(data.nil?)
      flash[:error] = 'No custom validators exist for this version.'
      redirect_to :back
    else
      send_data data, :filename => "form_#{@form.id}_#{params[:version]}.js"
    end
  end

  member_action :upload_config, :method => :post do
    @form = Form.find(params[:id])

    repo = GitConfigRepository.new

    unless(params[:form].nil? or (params[:form][:file].nil? or params[:form][:file].tempfile.nil?))
      repo.update_config_file(@form.relative_config_file_path, params[:form][:file].tempfile, current_user, "New configuration file for form #{@form.id}")
    end
    unless(params[:form].nil? or (params[:form][:validators].nil? or params[:form][:validators].tempfile.nil?))
      repo.update_config_file(@form.relative_validator_file_path, params[:form][:validators].tempfile, current_user, "New custom validations for form #{@form.id}")
    end
        
    redirect_to({:action => :show}, :notice => "Configuration successfully uploaded")
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
    if @form.nil? or @form.session.nil?
      flash[:error] = 'Template forms can not be locked/unlocked!'      
      redirect_to :action => :show
      return
    end

    if(cannot? :manage, @form)
      flash[:error] = 'You are not authorized to lock this form!'
      redirect_to :action => :show
      return
    end
    unless(@form.semantically_valid?)
      flash[:error] = 'The form still has validation errors. These need to be fixed before the form can be locked.'
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
    if @form.nil? or @form.session.nil?
      flash[:error] = 'Template forms can not be locked/unlocked!'      
      redirect_to :action => :show
      return
    end

    if(cannot? :manage, @form)
      flash[:error] = 'You are not authorized to unlock this form!'
      redirect_to :action => :show
      return
    end

    if(@form.session.state != :building)
      flash[:error] = 'The forms session is locked, can\'t unlock form!'
      redirect_to :action => :show
      return
    end

    @form.state = :draft
    @form.locked_version = nil
    @form.save

    redirect_to({:action => :show}, :notice => 'Form unlocked')
  end

  controller do
    def copy_to_session(form, session)
      authorize! :read, form
      authorize! :manage, session

      form.copy_to_session(session, current_user)
    end
  end

  member_action :copy, :method => :post do
    @form = Form.find(params[:id])
    @session = Session.find(params[:form][:session_id])

    copied_form = copy_to_session(@form, @session)

    subform_copy_count = 0
    if(params[:form][:include_subforms] == '1')
      @form.included_forms.each do |included_form_name|
        included_form = Form.where(:name => included_form_name, :session_id => @form.session_id).first
        next if included_form.nil?
        
        copy_to_session(included_form, @session)
        subform_copy_count += 1
      end
    end
    
    redirect_to(admin_form_path(copied_form), :notice => (subform_copy_count > 0 ? "Form and #{subform_copy_count} included forms copied" : 'Form copied'))
  end
  member_action :copy_form do
    @form = Form.find(params[:id])
    authorize! :read, @form
    
    @page_title = "Copy Form to Session"
  end
  action_item :only => :show do
    link_to 'Copy', copy_form_admin_form_path(resource)
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

  action_item :only => :show do
    link_to 'Preview', preview_form_path(resource), :target => '_blank' if resource.has_configuration? and can? :read, resource
  end
  action_item :only => :show do
    link_to 'Preview with Annotations', preview_form_path(resource, :show_internal_annotations => true), :target => '_blank' if resource.has_configuration? and can? :read, resource
  end
  
  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'form', :audit_trail_view_id => resource.id))
  end
end
