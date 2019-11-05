require 'git_config_repository'
require 'schema_validation'
require 'aa_erica_keywords'

ActiveAdmin.register Study do
  menu(parent: 'store', priority: 0)

  actions :index, :show if ERICA.remote?

  scope :all, default: true
  scope :building
  scope :production

  controller do
    def max_csv_records
      1_000_000
    end

    before_action :authorize_erica_remote, only: :index, if: -> { ERICA.remote? }
    def authorize_erica_remote
      return if params[:format].blank?
      authorize! :download_status_files, Study
    end
  end

  index do
    selectable_column
    column :name, sortable: :name do |study|
      link_to study.name, admin_study_path(study)
    end
    column :configuration do |study|
      if study.has_configuration?
        status_tag('Available', :ok)
      else
        status_tag('Missing', :error)
      end
    end
    column :state, sortable: :state do |study|
      study.state.to_s.camelize
    end
    column 'Select for Session' do |study|
      if can? :read, study
        link_to('Select', select_for_session_admin_study_path(study))
      else
        'n/A'
      end
    end

    customizable_default_actions(current_ability)
  end

  show do |study|
    attributes_table do
      row :name
      row :domino_db_url do
        if study.domino_integration_enabled?
          link_to(study.domino_db_url, study.domino_db_url)
        else
          status_tag('Disabled', :warning, label: 'Domino integration not enabled')
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
      keywords_row(study, :tags, 'Allowed Keywords', can?(:define_keywords, study)) if Rails.application.config.is_erica_remote

      if study.has_configuration?
        row :configuration_validation do
          render 'admin/shared/schema_validation_results', errors: study.validate
        end
      end
      row :configuration do
        current = {}
        if study.has_configuration?
          current_config = study.current_configuration
          if current_config.nil? || !current_config.is_a?(Hash)
            current[:configuration] = :invalid
          else
            current[:configuration] = CodeRay.scan(JSON.pretty_generate(current_config), :json).div(css: :class).html_safe
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
            locked[:configuration] = CodeRay.scan(JSON.pretty_generate(locked_config), :json).div(css: :class).html_safe
          end

          locked[:download_link] = download_locked_configuration_admin_study_path(study)
        end

        render 'admin/shared/config_table', current: current, locked: locked
      end
    end
    active_admin_comments if can?(:comment, study)
  end

  form do |f|
    inputs 'Details' do
      input :name, required: true
      if !f.object.persisted? || can?(:change_domino_config, f.object)
        input :domino_db_url, label: 'Domino DB URL', required: false, hint: (f.object.persisted? ? 'Do not change this unless you are absolutely sure you know what you do. This can lead to data corruption unless the Domino DB was moved from the old URL to the new one.' : 'If left blank, Domino integration will not be enabled for this study. You can enable it later by changing this value.')
        input :domino_server_name, label: 'Domino Server Name', required: false, hint: 'Please enter the name of the Domino Server as seen in Lotus Notes (without the domain after the slash), for example \'pharmtrace-server\' instead of \'pharmtrace-server/pharmtrace\'. This is used to generate links that refer to the server name instead of its IP address. If left blank, the IP/hostname from the Domino DB URL will be used instead.'
      end
      # f.form_buffers.last # https://github.com/gregbell/active_admin/pull/965
    end

    actions
  end

  # filters
  filter :name
  filter :state, as: :check_boxes, collection: Study::STATE_SYMS.each_with_index.map { |state, i| [state, i] }

  member_action :download_current_configuration do
    @study = Study.find(params[:id])
    authorize! :read, @study

    data = GitConfigRepository.new.data_at_version(@study.relative_config_file_path, nil)
    send_data data, filename: "study_#{@study.id}_current.yml" unless data.nil?
  end
  member_action :download_locked_configuration do
    @study = Study.find(params[:id])
    authorize! :read, @study

    data = GitConfigRepository.new.data_at_version(@study.relative_config_file_path, @study.locked_version)
    send_data data, filename: "study_#{@study.id}_#{@study.locked_version}.yml" unless data.nil?
  end
  member_action :download_configuration_at_version do
    @study = Study.find(params[:id])
    authorize! :read, @study
    @version = params[:config_version]

    data = GitConfigRepository.new.data_at_version(@study.relative_config_file_path, @version)
    send_data data, filename: "study_#{@study.id}_#{@version}.yml" unless data.nil?
  end
  member_action :upload_config, method: :post do
    @study = Study.find(params[:id])

    authorize!(:configure, @study)

    result = Study::UploadConfiguration.(params, current_user: current_user)
    if result.success?
      return redirect_to({ action: :show }, notice: 'Configuration successfully uploaded.')
    end

    @upload_configuration_form = result['contract.default']

    render 'admin/studies/upload_config', locals: { url: upload_config_admin_study_path }
  end
  member_action :upload_config_form, method: :get do
    @study = Study.find(params[:id])

    authorize!(:configure, @study)

    @upload_configuration_form = Study::Contract::UploadConfiguration.new(@study)

    @page_title = 'Upload new configuration'
    render 'admin/studies/upload_config', locals: { url: upload_config_admin_study_path }
  end

  action_item :configure, only: :show, if: -> { can?(:configure, study) } do
    link_to 'Upload configuration', upload_config_form_admin_study_path(study)
  end

  action_item :audit_trail, only: :show do
    link_to('Audit Trail', admin_versions_path(audit_trail_view_type: 'study', audit_trail_view_id: resource.id)) if can? :read, Version
  end

  member_action :select_for_session, method: :get do
    @study = Study.find(params[:id])
    authorize! :read, @study

    session[:selected_study_id] = @study.id
    session[:selected_study_name] = @study.name

    flash[:notice] = "Study #{@study.name} was selected for this session."
    redirect_back(fallback_location: admin_studies_path)
  end

  action_item :select, only: :show, if: -> { session[:selected_study_id] != resource.id } do
    link_to('Select for Session', select_for_session_admin_study_path(resource))
  end

  collection_action :selected_study, method: :get do
    if session[:selected_study_id].nil?
      flash[:error] = 'No study selected for current session.'
      redirect_to(admin_studies_path)
    else
      redirect_to(admin_study_path(session[:selected_study_id]))
    end
  end
  collection_action :deselect_study, method: :get do
    if session[:selected_study_id].nil?
      flash[:error] = 'No study selected for current session.'
      redirect_back(fallback_location: root_url)
    else
      session[:selected_study_id] = nil
      session[:selected_study_name] = nil
      flash[:notice] = 'The study was deselected for the current session.'
      redirect_back(fallback_location: root_url)
    end
  end

  action_item :deselect, only: :index, if: -> { session[:selected_study_name].present? } do
    link_to('Deselect Study', deselect_study_admin_studies_path)
  end

  action_item :deselect, only: :show, if: -> { session[:selected_study_id] == resource.id } do
    link_to('Deselect Study', deselect_study_admin_studies_path)
  end

  member_action :lock do
    @study = Study.find(params[:id])

    if cannot? :manage, @study
      flash[:error] = 'You are not authorized to lock this study!'
      redirect_to action: :show
      return
    end
    unless @study.semantically_valid?
      flash[:error] = 'The study still has validation errors. These need to be fixed before the study can be locked.'
      redirect_to action: :show
      return
    end

    @study.state = :production
    @study.locked_version = GitConfigRepository.new.current_version
    @study.save

    redirect_to({ action: :show }, notice: 'Study locked')
  end
  member_action :unlock do
    @study = Study.find(params[:id])

    if cannot? :manage, @study
      flash[:error] = 'You are not authorized to unlock this study!'
      redirect_to action: :show
      return
    end

    @study.state = :building
    @study.locked_version = nil
    @study.save

    redirect_to({ action: :show }, notice: 'Form unlocked')
  end

  action_item :lock, only: :show, if: -> { resource.state == :building } do
    next unless can? :manage, study
    link_to 'Lock', lock_admin_study_path(resource)
  end

  action_item :unlock, only: :show, if: -> { resource.state == :production } do
    next unless can? :manage, study
    link_to 'Unlock', unlock_admin_study_path(resource)
  end

  member_action :autocomplete_tags do
    study = Study.find(params[:id])
    authorize! :edit_keywords, study

    tags = study.tags_on(params[:context]).where('name LIKE ?', params[:q] + '%').order(:name)

    respond_to do |format|
      format.json { render json: tags.map { |t| { id: t.name, name: t.name } } }
    end
  end

  viewer_cartable(:study)
  erica_keywordable(:tags, 'Allowed Keywords') if Rails.application.config.is_erica_remote
end
