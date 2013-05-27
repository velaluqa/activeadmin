require 'git_config_repository'
require 'schema_validation'

ActiveAdmin.register Study do

  controller do
    load_and_authorize_resource :except => :index
    skip_load_and_authorize_resource :only => []
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
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
      row :notes_links_base_uri do
        link_to(study.notes_links_base_uri, study.notes_links_base_uri) unless study.notes_links_base_uri.nil?
      end
      row :image_storage_path

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
  end
  
  form do |f|
    f.inputs 'Details' do
      f.input :name, :required => true
      if(!f.object.persisted? or current_user.is_app_admin?)
        f.input :domino_db_url, :label => 'Domino DB URL', :required => false, :hint => (f.object.persisted? ? 'Do not change this unless you are absolutely sure you know what you do. This can lead to data corruption unless the Domino DB was moved from the old URL to the new one.' : 'If left blank, Domino integration will not be enabled for this study. You can enable it later by changing this value.')
      end
      f.form_buffers.last # https://github.com/gregbell/active_admin/pull/965
    end

    f.buttons
  end

  # filters
  filter :name

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

  viewer_cartable(:study)
end
