require 'git_config_repository'

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
        link_to(study.domino_db_url, study.domino_db_url)
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
        f.input :domino_db_url, :label => 'Domino DB URL', :required => true, :hint => (f.object.persisted? ? 'Do not change this unless you are absolutely sure you know what you do. This can lead to data corruption unless the Domino DB was moved from the old URL to the new one.' : '')
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
      repo = GitConfigRepository.new
      repo.update_config_file(@study.relative_config_file_path, params[:study][:file].tempfile, current_user, "New configuration file for study #{@study.id}")
        
      redirect_to({:action => :show}, :notice => "Configuration successfully uploaded")
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
