require 'git_config_repository'
require 'schema_validation'

ActiveAdmin.register Study do

  menu if: proc { can? :read, Study }

  scope :all, :default => true
  scope :building
  scope :production

  controller do
    load_and_authorize_resource :except => :index
    skip_load_and_authorize_resource :only => [:lock, :unlock]

    def max_csv_records
      1_000_000
    end

    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end

    def index
      authorize! :download_status_files, Study if(Rails.application.config.is_erica_remote and not params[:format].blank?)

      index!
    end
  end

  index do
    selectable_column
    column :name, :sortable => :name do |study|
      link_to study.name, admin_study_path(study)
    end
    column :configuration do |study|
      if(study.has_configuration?)
        status_tag('Available', :ok)
      else
        status_tag('Missing', :error)
      end
    end
    column :state, :sortable => :state do |study|
      study.state.to_s.camelize
    end
    column 'Select for Session' do |study|
      link_to('Select', select_for_session_admin_study_path(study))
    end
    
    default_actions
  end

  show do |study|
    attributes_table do
      row :name
      row :domino_db_url do
        if study.domino_integration_enabled?
          link_to(study.domino_db_url, study.domino_db_url)
        else
          status_tag('Disabled', :warning, :label => "Domino integration not enabled")
        end
      end
      row :domino_server_name
      row :notes_links_base_uri do
        link_to(study.notes_links_base_uri, study.notes_links_base_uri) unless study.notes_links_base_uri.nil?
      end
      row :image_storage_path

      row :state do
        study.state.to_s.camelize + (study.locked_version.nil? ? '' : " (Version: #{study.locked_version})")
      end

      if study.has_configuration?
        row :configuration_validation do
          render 'admin/shared/schema_validation_results', :errors => study.validate
        end
      end
      row :configuration do
        current = {}
        if study.has_configuration?
          current_config = study.current_configuration 
          if(current_config.nil? or not current_config.is_a?(Hash))
            current[:configuration] = :invalid
          else
            current[:configuration] = CodeRay.scan(JSON::pretty_generate(current_config), :json).div(:css => :class).html_safe
          end
          
          current[:download_link] = download_current_configuration_admin_study_path(study)
        end
        locked = nil
        unless study.locked_version.nil?
          locked = {}
    
          locked_config = study.locked_configuration
          if locked_config.nil?
            locked[:configuration] = :invalid
          else
            locked[:configuration] = CodeRay.scan(JSON::pretty_generate(locked_config), :json).div(:css => :class).html_safe
          end
          
          locked[:download_link] = download_locked_configuration_admin_study_path(study)
        end

        render 'admin/shared/config_table', :current => current, :locked => locked
      end
    end
    active_admin_comments if can? :remote_comment, study
  end
  
  form do |f|
    f.inputs 'Details' do
      f.input :name, :required => true
      if(!f.object.persisted? or current_user.is_app_admin?)
        f.input :domino_db_url, :label => 'Domino DB URL', :required => false, :hint => (f.object.persisted? ? 'Do not change this unless you are absolutely sure you know what you do. This can lead to data corruption unless the Domino DB was moved from the old URL to the new one.' : 'If left blank, Domino integration will not be enabled for this study. You can enable it later by changing this value.')
        f.input :domino_server_name, :label => 'Domino Server Name', :required => false, :hint => 'Please enter the name of the Domino Server as seen in Lotus Notes (without the domain after the slash), for example \'pharmtrace-server\' instead of \'pharmtrace-server/pharmtrace\'. This is used to generate links that refer to the server name instead of its IP address. If left blank, the IP/hostname from the Domino DB URL will be used instead.'
      end
      f.form_buffers.last # https://github.com/gregbell/active_admin/pull/965
    end

    f.buttons
  end

  # filters
  filter :name
  filter :state, :as => :check_boxes, :collection => Study::STATE_SYMS.each_with_index.map {|state, i| [state, i]}

  member_action :download_current_configuration do
    @study = Study.find(params[:id])
    authorize! :read, @study

    data = GitConfigRepository.new.data_at_version(@study.relative_config_file_path, nil)
    send_data data, :filename => "study_#{@study.id}_current.yml" unless data.nil?
  end
  member_action :download_locked_configuration do    
    @study = Study.find(params[:id])
    authorize! :read, @study

    data = GitConfigRepository.new.data_at_version(@study.relative_config_file_path, @study.locked_version)
    send_data data, :filename => "study_#{@study.id}_#{@study.locked_version}.yml" unless data.nil?
  end
  member_action :download_configuration_at_version do
    @study = Study.find(params[:id])
    authorize! :read, @study
    @version = params[:config_version]

    data = GitConfigRepository.new.data_at_version(@study.relative_config_file_path, @version)
    send_data data, :filename => "study_#{@study.id}_#{@version}.yml" unless data.nil?
  end
  member_action :upload_config, :method => :post do
    @study = Study.find(params[:id])

    if(params[:study].nil? or params[:study][:file].nil? or params[:study][:file].tempfile.nil?)
      flash[:error] = "You must specify a configuration file to upload"
      redirect_to({:action => :show})
    else
      current_config = @study.current_configuration
      old_visit_types = (current_config.nil? or current_config['visit_types'].nil? ? [] : current_config['visit_types'].keys)

      begin
        new_config = YAML.load_file(params[:study][:file].tempfile)

        validator = SchemaValidation::StudyValidator.new
        new_config = nil unless(validator.validate(new_config).empty?)
      rescue
        new_config = nil
      end

      # if the new config is invalid YAML, we won't apply any changed
      nullified_visits = 0
      unless(new_config.nil?)
        new_visit_types = (new_config['visit_types'].nil? ? [] : new_config['visit_types'].keys)
        removed_visit_types = (old_visit_types - new_visit_types).uniq

        @study.visits.where(:visit_type => removed_visit_types).each do |visit|
          pp visit
          visit.visit_type = nil
          visit.save
          nullified_visits += 1
        end
      end
      
      repo = GitConfigRepository.new
      repo.update_config_file(@study.relative_config_file_path, params[:study][:file].tempfile, current_user, "New configuration file for study #{@study.id}")
        
      redirect_to({:action => :show}, :notice => 'Configuration successfully uploaded.' + (nullified_visits == 0 ? '' : " #{nullified_visits} visits had their visit type reset, because their former visit type no longer exists."))
    end
  end
  member_action :upload_config_form, :method => :get do
    @study = Study.find(params[:id])
    
    @page_title = "Upload new configuration"
    render 'admin/studies/upload_config', :locals => { :url => upload_config_admin_study_path}
  end
  action_item :only => :show do
    link_to 'Upload configuration', upload_config_form_admin_study_path(study) if can? :manage, study
  end

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'study', :audit_trail_view_id => resource.id))
  end

  member_action :select_for_session, :method => :get do
    @study = Study.find(params[:id])
    
    session[:selected_study_id] = @study.id
    session[:selected_study_name] = @study.name

    redirect_to :back, :notice => "Study #{@study.name} was selected for this session."
  end
  action_item :only => :show do
    link_to('Select for Session', select_for_session_admin_study_path(resource))
  end
  collection_action :selected_study, :method => :get do
    if(session[:selected_study_id].nil?)
      flash[:error] = 'No study selected for current session.'
      redirect_to(admin_studies_path)
    else
      redirect_to(admin_study_path(session[:selected_study_id]))
    end
  end
  collection_action :deselect_study, :method => :get do
    if(session[:selected_study_id].nil?)
      flash[:error] = 'No study selected for current session.'
      redirect_to :back
    else
      session[:selected_study_id] = nil
      session[:selected_study_name] = nil
      redirect_to :back, :notice => 'The study was deselected for the current session.'
    end
  end
  action_item :only => :index do
    link_to('Deselect Study', deselect_study_admin_studies_path) unless session[:selected_study_id].nil?
  end

  member_action :lock do
    @study = Study.find(params[:id])

    if(cannot? :manage, @study)
      flash[:error] = 'You are not authorized to lock this study!'
      redirect_to :action => :show
      return
    end
    unless(@study.semantically_valid?)
      flash[:error] = 'The study still has validation errors. These need to be fixed before the study can be locked.'
      redirect_to :action => :show
      return
    end

    @study.state = :production
    @study.locked_version = GitConfigRepository.new.current_version
    @study.save

    redirect_to({:action => :show}, :notice => 'Study locked')
  end
  member_action :unlock do
    @study = Study.find(params[:id])

    if(cannot? :manage, @study)
      flash[:error] = 'You are not authorized to unlock this study!'
      redirect_to :action => :show
      return
    end

    @study.state = :building
    @study.locked_version = nil
    @study.save

    redirect_to({:action => :show}, :notice => 'Form unlocked')
  end
  action_item :only => :show do
    next unless can? :manage, study

    if resource.state == :building
      link_to 'Lock', lock_admin_study_path(resource)
    elsif resource.state == :production
      link_to 'Unlock', unlock_admin_study_path(resource)
    end
  end


  viewer_cartable(:study)
end
