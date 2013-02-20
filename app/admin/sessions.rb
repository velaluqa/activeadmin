require 'git_config_repository'
require 'aa_customizable_default_actions'

ActiveAdmin.register Session do

  config.clear_action_items! # get rid of the default action items, since we have to handle 'edit' and 'delete' on a case-by-case basis

  scope :all, :default => true
  scope :building
  scope :testing
  scope :production
  scope :closed

  controller do
    load_and_authorize_resource :except => :index
    skip_load_and_authorize_resource :only => [:download_current_configuration, :download_locked_configuration, :switch_state]
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end

    def update
      if params[:session][:study_id] != Session.find(params[:id]).study_id
        flash[:error] = 'A session can no be moved to a new study!'
        redirect_to :action => :show
        return
      end

      update!
    end
  end

  index do
    selectable_column

    column :name do |session|
      link_to session.name, admin_session_path(session)
    end
    column :study
    column 'Readers' do |session|
      session.readers.size
    end
    column 'Validators' do |session|
      session.validators.size
    end
    column :state do |session|
      session.state.to_s.camelize
    end
    column 'Progress' do |session|
      "#{session.case_list(:read).size} / #{session.case_list(:all).size}"
    end
    column :configuration do |session|
      if(session.has_configuration?)
        status_tag('Available', :ok)
      else
        status_tag('Missing', :error)
      end
    end

    customizable_default_actions do |session|
      except = []
      except << :destroy unless can? :destroy, session
      except << :edit unless can? :edit, session
      
      except
    end
  end

  show do |session|
    attributes_table do
      row :name
      row :study
      # TODO: remove, is just for testing
      row :rights do
        if(can? :validate, session and can? :blind_read, session)
          status_tag('Both', :error)
        elsif(can? :validate, session)
          status_tag('Validator', :ok)
        elsif(can? :blind_read, session)
          status_tag('Reader', :ok)
        else
          status_tag('None', :error)
        end
      end
      row :readers do
        if can? :manage, session
          render 'admin/sessions/list', :items => session.readers.map {|r| link_to(r.name, admin_user_path(r)) + ' (' + link_to('-', remove_reader_admin_session_path(session, :reader_id => r.id)) +')' }, :action_link => link_to('Add Reader', add_reader_form_admin_session_path(session)).html_safe
        else
          render 'admin/sessions/list', :items => session.readers.map {|r| link_to(r.name, admin_user_path(r))}
        end
      end
      row :validators do
        if can? :manage, session
          render 'admin/sessions/list', :items => session.validators.map {|v| link_to(v.name, admin_user_path(v)) + ' (' + link_to('-', remove_validator_admin_session_path(session, :validator_id => v.id)) +')' }, :action_link => link_to('Add Validator', add_validator_form_admin_session_path(session)).html_safe
        else
          render 'admin/sessions/list', :items => session.validators.map {|v| link_to(v.name, admin_user_path(v))}
        end
      end
      row :state do
        session.state.to_s.camelize + (session.locked_version.nil? ? '' : " (Version: #{session.locked_version})")
      end
      row :cases do
        if session.case_list(:all).empty?
          nil
        else
          render 'admin/sessions/list', :items => session.case_list(:all).map {|c| link_to(c.name, admin_case_path(c))}
        end
      end
      row :configuration do
        table do
          thead do
            tr do
              th do
                "Current"                
              end
              unless session.locked_version.nil?
                th do
                  "Locked"
                end
              end
            end
          end
          tbody do
            tr do
              td do 
                if session.has_configuration?
                  link_to 'Download Current Configuration', download_current_configuration_admin_session_path(session)
                else
                  status_tag('Missing', :error)
                end
              end
              unless session.locked_version.nil?
                td do
                  link_to 'Download Locked Configuration', download_locked_configuration_admin_session_path(session)                  
                end
              end
            end
            tr do
              td do
                config = session.current_configuration if session.has_configuration?

                if not session.has_configuration?
                  status_tag('Missing', :error)       
                elsif config.nil?
                  status_tag('Invalid', :warning)
                else
                  CodeRay.scan(JSON::pretty_generate(config), :json).div(:css => :class).html_safe
                end
              end
              unless session.locked_version.nil?
                td do
                  config = session.locked_configuration
                  
                  if config.nil?
                    status_tag('Invalid', :warning)
                  else
                    CodeRay.scan(JSON::pretty_generate(config), :json).div(:css => :class).html_safe
                  end
                end
              end
            end
          end
        end
      end
      if session.has_configuration?
        row :configuration_validation do        
          render 'admin/shared/schema_validation_results', :errors => session.validate
        end
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      unless f.object.persisted?
        f.input :study
      end
      f.input :name
    end
    
    f.buttons
  end

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

  member_action :remove_reader, :method => :get do
    @session = Session.find(params[:id])
    @reader = User.find(params[:reader_id])

    @session.readers.delete(@reader)
    redirect_to :action => :show
  end
  member_action :remove_validator, :method => :get do
    @session = Session.find(params[:id])
    @validator = User.find(params[:validator_id])

    @session.validators.delete(@validator)
    redirect_to :action => :show
  end

  member_action :add_reader, :method => :post do
    @session = Session.find(params[:id])
    @reader = User.find(params[:user][:user])

    if @reader.nil?
      flash[:error] = 'The selected user does not exist'
      redirect_to :action => :show
    else
      @session.readers << @reader unless @session.readers.exists? @reader
      redirect_to({:action => :show}, :notice => "User #{@reader.username} was added as a Reader")
    end
  end
  member_action :add_reader_form, :method => :get do
    @session = Session.find(params[:id])
    
    @page_title = "Add Reader to Session"
    render 'admin/sessions/select_user', :locals => { :url => add_reader_admin_session_path }
  end
  member_action :add_validator, :method => :post do
    @session = Session.find(params[:id])
    @validator = User.find(params[:user][:user])

    if @validator.nil?
      flash[:error] = 'The selected user does not exist'
      redirect_to :action => :show
    else
      @session.validators << @validator unless @session.validators.exists? @validator
      redirect_to({:action => :show}, :notice => "User #{@validator.username} was added as a Validator")
    end
  end
  member_action :add_validator_form, :method => :get do
    @session = Session.find(params[:id])
    
    @page_title = "Add Validator to Session"
    render 'admin/sessions/select_user', :locals => { :url => add_validator_admin_session_path }
  end

  member_action :import_case_list_csv, :method => :post do
    @session = Session.find(params[:id])

    num_imported = Case.batch_create_from_csv(params[:session][:file].tempfile, @session, @session.next_position)

    redirect_to({:action => :show}, :notice => "Successfully imported #{num_imported} cases from CSV")
  end
  member_action :import_case_list_csv_form, :method => :get do
    @session = Session.find(params[:id])

    @page_title = "Import Case List from CSV"
    render 'admin/sessions/import_csv_form', :locals => {:url => import_case_list_csv_admin_session_path}
  end
  action_item :only => :show do
    link_to 'Import Case List from CSV', import_case_list_csv_form_admin_session_path(session) if can? :manage, session
  end
  
  member_action :import_patient_data_csv, :method => :post do
    @session = Session.find(params[:id])

    num_imported = Patient.batch_create_from_csv(params[:session][:file].tempfile, @session)

    redirect_to({:action => :show}, :notice => "Successfully imported/updated #{num_imported} patients from CSV")
  end
  member_action :import_patient_data_csv_form, :method => :get do
    @session = Session.find(params[:id])

    @page_title = "Import Patient Data from CSV"
    render 'admin/sessions/import_csv_form', :locals => {:url => import_patient_data_csv_admin_session_path}
  end
  action_item :only => :show do
    link_to 'Import Patient Data from CSV', import_patient_data_csv_form_admin_session_path(session) if can? :manage, session
  end

  member_action :download_current_configuration do
    @session = Session.find(params[:id])
    authorize! :read, @session

    data = GitConfigRepository.new.data_at_version(@session.relative_config_file_path, nil)
    send_data data, :filename => "session_#{@session.id}_current.yml" unless data.nil?
  end
  member_action :download_locked_configuration do
    @session = Session.find(params[:id])
    authorize! :read, @session

    data = GitConfigRepository.new.data_at_version(@session.relative_config_file_path, @session.locked_version)
    send_data data, :filename => "session_#{@session.id}_#{@session.locked_version}.yml" unless data.nil?
  end
  member_action :upload_config, :method => :post do
    @session = Session.find(params[:id])

    if(params[:session].nil? or params[:session][:file].nil? or params[:session][:file].tempfile.nil?)
      flash[:error] = "You must specify a configuration file to upload"
      redirect_to({:action => :show})
    else
      repo = GitConfigRepository.new
      repo.update_config_file(@session.relative_config_file_path, params[:session][:file].tempfile, current_user, "New configuration file for session #{@session.id}")
        
      redirect_to({:action => :show}, :notice => "Configuration successfully uploaded")
    end
  end
  member_action :upload_config_form, :method => :get do
    @session = Session.find(params[:id])
    
    @page_title = "Upload new configuration"
    render 'admin/sessions/upload_config', :locals => { :url => upload_config_admin_session_path}
  end
  action_item :only => :show do
    link_to 'Upload configuration', upload_config_form_admin_session_path(session) if can? :manage, session
  end

  controller do
    def switch_session_state(session_id, new_state)
      session = Session.find(session_id)
      return if session.nil?

      if(session.state == :closed)
        authorize! :manage, :system
      elsif(cannot? :manage, session)
        authorize! :manage, session
      end
      if(session.state == :building and new_state == :testing and not session.semantically_valid?)
        flash[:error] = 'The session still has validation errors. These need to be fixed before the session can be moved into testing.'
        redirect_to :action => :show
        return
      end
      unless resource.forms.map {|f| f.state == :final}.reduce {|a,b| a and b}
        flash[:error] = 'Not all forms belonging to this session are locked. Please lock all associated forms before moving the session into testing.'
        redirect_to :action => :show
        return
      end

      case new_state
      when :building
        session.locked_version = nil
      when :testing
        session.locked_version = GitConfigRepository.new.current_version if session.state == :building
      end
      session.state = new_state
      pp session
      session.save
      pp Session.find(session_id)

      redirect_to({:action => :show}, :notice => "State changed to #{new_state.to_s.camelize}")
    end
  end

  member_action :switch_state, :method => :get do
    switch_session_state(params[:id], params[:new_state].to_sym)
  end

  action_item :only => :show do
    next unless can? :manage, resource
    case resource.state
    when :building
      link_to 'Start Testing', switch_state_admin_session_path(resource, {:new_state => :testing}) if (resource.forms.map {|f| f.state == :final}.reduce {|a,b| a and b} and can? :manage, resource)
    when :testing
      link_to 'Start Production', switch_state_admin_session_path(resource, {:new_state => :production}) if can? :manage, resource
    when :production
      link_to 'Close Session', switch_state_admin_session_path(resource, {:new_state => :closed}) if can? :manage, resource
    end
  end
  action_item :only => :show do
    case resource.state
    when :testing
      link_to 'Abort Testing', switch_state_admin_session_path(resource, {:new_state => :building}) if can? :manage, resource
    when :production
      link_to 'Abort Production', switch_state_admin_session_path(resource, {:new_state => :testing}) if can? :manage, resource
    when :closed
      link_to 'Reopen Session', switch_state_admin_session_path(resource, {:new_state => :production}) if can? :manage, :system
    end
  end
end
