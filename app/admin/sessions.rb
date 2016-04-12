require 'git_config_repository'
require 'aa_customizable_default_actions'
require 'config_display_filters'

ActiveAdmin.register Session do

  menu if: proc { can? :read, Session }

  config.clear_action_items! # get rid of the default action items, since we have to handle 'edit' and 'delete' on a case-by-case basis

  scope :all, :default => true
  scope :building
  scope :testing
  scope :production
  scope :closed

  config.comments = false

  controller do
    load_and_authorize_resource :except => :index
    skip_load_and_authorize_resource :only => [:download_current_configuration, :download_locked_configuration, :download_configuration_at_version, :switch_state, :deep_clone_form, :deep_clone]

    def max_csv_records
      1_000_000
    end

    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end

    def update
      if(params[:session][:study_id] and params[:session][:study_id] != Session.find(params[:id]).study_id)
        flash[:error] = 'A session cannot be moved to a new study!'
        redirect_to :action => :show
        return
      end

      update!
    end
  end

  index do
    selectable_column

    column :name, :sortable => :name do |session|
      link_to session.name, admin_session_path(session)
    end
    column :study, :sortable => :study_id
    column 'Readers' do |session|
      session.readers.size
    end
    column 'Validators' do |session|
      session.validators.size
    end
    column :state, :sortable => :state do |session|
      session.state.to_s.camelize
    end
    column 'Progress' do |session|
      session.case_list(:read).size.to_s + ' / ' + session.case_list(:all).size.to_s
    end
    column :configuration do |session|
      if(session.has_configuration?)
        status_tag('Available', :ok)
      else
        status_tag('Missing', :error)
      end
    end

    customizable_default_actions(current_ability)
  end

  show do |session|
    attributes_table do
      row :name
      row :study
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
      row :export do
        ul do
          li { link_to('All Cases', export_cases_admin_session_path(session, :export_state => :all, :export_kind => :all)) }
          li { link_to('All Regular Cases', export_cases_admin_session_path(session, :export_state => :all, :export_kind => :regular)) }
          li { link_to('All Validation Cases', export_cases_admin_session_path(session, :export_state => :all, :export_kind => :validation)) }
          li { link_to('All Reader Testing Cases', export_cases_admin_session_path(session, :export_state => :all, :export_kind => :reader_testing)) }
          li { link_to('Unexported Cases', export_cases_admin_session_path(session, :export_state => :unexported, :export_kind => :all)) }
          li { link_to('Unexported Regular Cases', export_cases_admin_session_path(session, :export_state => :unexported, :export_kind => :regular)) }
          li { link_to('Unexported Validation Cases', export_cases_admin_session_path(session, :export_state => :unexported, :export_kind => :validation)) }
          li { link_to('Unexported Reader Testing Cases', export_cases_admin_session_path(session, :export_state => :unexported, :export_kind => :reader_testing)) }
        end
      end
      row :reorder_cases do
        link_to('Reorder Case List', reorder_case_list_form_admin_session_path(session))
      end
      row :cases do
        if session.case_list(:all).empty?
          nil
        else
          render 'admin/sessions/list', :items => session.case_list(:all).map {|c| link_to(c.name, admin_case_path(c))}
        end
      end
      row :annotations_layouts do
        link_to 'Upload Annotations Layouts', upload_annotations_layouts_form_admin_session_path(session)
      end
      if session.has_configuration?
        row :configuration_validation do        
          render 'admin/shared/schema_validation_results', :errors => session.validate
        end
      end
      row :configuration do
        current = {}
        if session.has_configuration?
          current_config = session.current_configuration 
          if(current_config.nil? or not current_config.is_a?(Hash))
            current[:configuration] = :invalid
          else
            current[:configuration] = CodeRay.scan(JSON::pretty_generate(ConfigDisplayFilters::filter_session_config(current_config)), :json).div(:css => :class).html_safe
          end
          
          current[:download_link] = download_current_configuration_admin_session_path(session)
        end
        locked = nil
        unless session.locked_version.nil?
          locked = {}
    
          locked_config = session.locked_configuration
          if locked_config.nil?
            locked[:configuration] = :invalid
          else
            locked[:configuration] = CodeRay.scan(JSON::pretty_generate(ConfigDisplayFilters::filter_session_config(locked_config)), :json).div(:css => :class).html_safe
          end
          
          locked[:download_link] = download_locked_configuration_admin_session_path(session)
        end

        render 'admin/shared/config_table', :current => current, :locked => locked
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

  # filters
  filter :study, :collection => Proc.new { Study.accessible_by(current_ability).order('id ASC') }
  filter :name
  filter :state, :as => :check_boxes, :collection => Session::STATE_SYMS.each_with_index.map {|state, i| [state, i]}

  # copied from activeadmin/lib/active_admin/resource/action_items.rb#add_default_action_items
  action_item :edit, :except => [:new, :show] do
    if controller.action_methods.include?('new') and can? :manage, Session
      link_to(I18n.t('active_admin.new_model', :model => active_admin_config.resource_label), new_resource_path)
    end
  end
  action_item :edit, :only => :show do
    if controller.action_methods.include?('edit') and can? :edit, resource
      link_to(I18n.t('active_admin.edit_model', :model => active_admin_config.resource_label), edit_resource_path(resource))
    end
  end
  action_item :edit, :only => :show do
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

    if(params[:session].nil? or params[:session][:annotations_layout_mode].blank? or params[:session][:file].blank?)
      flash[:error] = "You must specifiy all the required parameters."
      redirect_to({:action => :show})
      return
    end

    num_imported = Case.batch_create_from_csv(params[:session][:file].tempfile, params[:session][:annotations_layout_mode].to_sym, @session, @session.next_position)

    redirect_to({:action => :show}, :notice => "Successfully imported #{num_imported} cases from CSV")
  end
  member_action :import_case_list_csv_form, :method => :get do
    @session = Session.find(params[:id])

    @page_title = "Import Case List from CSV"
  end
  action_item :edit, :only => :show do
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
  end
  action_item :edit, :only => :show do
    link_to 'Import Patient Data from CSV', import_patient_data_csv_form_admin_session_path(session) if can? :manage, session
  end

  member_action :download_current_configuration do
    @session = Session.find(params[:id])
    authorize! :read, @session

    data = GitConfigRepository.new.data_at_version(@session.relative_config_file_path, nil)
    if(data.nil?)
      flash[:error] = 'No configuration exist for this version.'
      redirect_to :back
    else
      send_data data, :filename => "session_#{@session.id}_current.yml"
    end
  end
  member_action :download_locked_configuration do
    @session = Session.find(params[:id])
    authorize! :read, @session

    data = GitConfigRepository.new.data_at_version(@session.relative_config_file_path, @session.locked_version)
    if(data.nil?)
      flash[:error] = 'No configuration exist for this version.'
      redirect_to :back
    else
      send_data data, :filename => "session_#{@session.id}_#{@session.locked_version}.yml"
    end
  end
  member_action :download_configuration_at_version do
    @session = Session.find(params[:id])
    authorize! :read, @session

    data = GitConfigRepository.new.data_at_version(@session.relative_config_file_path, params[:version])
    if(data.nil?)
      flash[:error] = 'No configuration exist for this version.'
      redirect_to :back
    else
      send_data data, :filename => "session_#{@session.id}_#{params[:version]}.yml"
    end
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
  action_item :edit, :only => :show do
    link_to 'Upload configuration', upload_config_form_admin_session_path(session) if can? :manage, session
  end

  member_action :upload_annotations_layouts, :method => :post do
    @session = Session.find(params[:id])    

    if(params[:session].nil? or params[:session][:case_type].blank? or params[:session][:annotations_layout_mode].blank? or params[:session][:file].blank?)
      flash[:error] = "You must specifiy all the required parameters."
      redirect_to({:action => :show})
      return
    end

    base64_layout = Base64.encode64(params[:session][:file].tempfile.read)

    config = @session.current_configuration
    params[:session][:case_type].reject {|ct| ct.blank?}.each do |case_type_name|
      case_type = config['types'][case_type_name]
      if(case_type.nil?)
        flash[:error] = "You specified an invalid case type '#{params[:session][:case_type]}'."
        redirect_to({:action => :show})
        return
      end

      if(params[:session][:annotations_layout_mode] == 'validation')
        case_type['validation'] = {} if case_type['validation'].nil?
        case_type['validation']['annotations_layout'] = base64_layout
      else
        case_type['annotations_layout'] = base64_layout
      end
    end

    begin
      File.open(@session.config_file_path, 'w+') do |f|
        f.write(config.to_yaml)
      end
      repo = GitConfigRepository.new
      repo.update_path(@session.relative_config_file_path, current_user, "New annotations layout for session #{@session.id}")
    rescue Exception => e
      flash[:error] = "Updating the configuration with the new annotations layout failed: #{e.message}"
      redirect_to({:action => :show})
      return
    end
      
    redirect_to({:action => :show}, :notice => "Annotations Layout successfully uploaded")
  end
  member_action :upload_annotations_layouts_form, :method => :get do
    @session = Session.find(params[:id])
    config = @session.current_configuration
    if config.nil?
      redirect_to :action => :show
      return
    end
    @case_types = config['types'].map {|k,v| k}
    
    @page_title = "Upload Annotations Layouts"
    render 'admin/sessions/upload_annotations_layouts', :locals => { :url => upload_annotations_layouts_admin_session_path}
  end

  member_action :export_cases, :method => :get do
    @session = Session.find(params[:id])
    
    case params[:export_state]
    when 'all'
      if(params[:export_kind] == 'all')
        cases = @session.cases
      else
        cases = @session.cases.where(:flag => Case::flag_sym_to_int(params[:export_kind].to_sym))
      end
    when 'unexported'
      if(params[:export_kind] == 'all')
        cases = @session.cases.where(:exported_at => nil)
      else
        cases = @session.cases.where(:exported_at => nil, :flag => Case::flag_sym_to_int(params[:export_kind].to_sym))
      end
    else
      cases = []
    end
    case_ids = cases.reject {|c| c.form_answer.nil?}.map {|c| c.id}

    render 'admin/cases/export_settings', :locals => {:selection => case_ids}
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

  action_item :edit, :only => :show do
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
  action_item :edit, :only => :show do
    case resource.state
    when :testing
      link_to 'Abort Testing', switch_state_admin_session_path(resource, {:new_state => :building}) if can? :manage, resource
    when :production
      link_to 'Abort Production', switch_state_admin_session_path(resource, {:new_state => :testing}) if can? :manage, resource
    when :closed
      link_to 'Reopen Session', switch_state_admin_session_path(resource, {:new_state => :production}) if can? :manage, :system
    end
  end

  controller do
    def cases_counts(sessions)
      cases_counts = {}

      sessions.each do |session|
        counts = {}

        Case::STATE_SYMS.each do |state|
          counts[state] = {}

          Case::FLAG_SYMS.each do |flag|
            counts[state][flag] = session.cases.where(:flag => Case::flag_sym_to_int(flag), :state => Case::state_sym_to_int(state)).size
          end
        end

        cases_counts[session.id] = counts
      end

      return cases_counts
    end

    def reader_cases(sessions)
      reader_cases = {}

      sessions.each do |session|
        cases = []

        session.readers.each do |reader|
          readers_cases = session.cases.reject { |c| c.form_answer.nil? or c.form_answer.user.id != reader.id }
          cases << {:reader => reader, :cases => readers_cases}
        end

        reader_cases[session.id] = cases
      end

      return reader_cases
    end
  end

  member_action :config_summary_report, :method => :get do
    @session = Session.find(params[:id])

    case_flag = (params[:case_flag] == 'validation' ? :validation : :regular)

    @session_config_versions = {}
    @form_config_versions = {}
    @session_config_version_dates = {}
    @form_config_version_dates = {}
    @forms = {}
    @session.cases.where(:flag => Case::flag_sym_to_int(case_flag)).find_each do |c|
      form_answer = c.form_answer
      next if form_answer.nil?

      form_versions = form_answer.form_versions
      next if form_versions.nil?

      @session_config_versions[form_versions['session']] ||= []
      @session_config_versions[form_versions['session']] << c.id

      @session_config_version_dates[form_versions['session']] ||= {:min => form_answer.submitted_at, :max => form_answer.submitted_at}
      @session_config_version_dates[form_versions['session']][:min] = form_answer.submitted_at if form_answer.submitted_at < @session_config_version_dates[form_versions['session']][:min]
      @session_config_version_dates[form_versions['session']][:max] = form_answer.submitted_at if form_answer.submitted_at > @session_config_version_dates[form_versions['session']][:max]

      form_versions.reject {|v| v == 'session'}.each do |form_id, version|
        form_id = form_id.to_i
        @forms[form_id] ||= Form.find(form_id)

        @form_config_versions[form_id] ||= {}
        @form_config_versions[form_id][version] ||= []
        @form_config_versions[form_id][version] << c.id

        @form_config_version_dates[form_id] ||= {}
        @form_config_version_dates[form_id][version] ||= {:min => form_answer.submitted_at, :max => form_answer.submitted_at}
        @form_config_version_dates[form_id][version][:min] = form_answer.submitted_at if form_answer.submitted_at < @form_config_version_dates[form_id][version][:min]
        @form_config_version_dates[form_id][version][:max] = form_answer.submitted_at if form_answer.submitted_at > @form_config_version_dates[form_id][version][:max]
      end
    end

    @session_config_version_dates = @session_config_version_dates.sort_by {|e| e[1][:min]}

    sorted_form_config_version_dates = {}
    @form_config_version_dates.each do |form_id, versions|
      sorted_form_config_version_dates[form_id] = versions.sort_by {|e| e[1][:min]}
    end
    @form_config_version_dates = sorted_form_config_version_dates

    @page_title = 'Config Summary Report'
    @page_title += case case_flag
                   when :regular
                     ' (Regular Cases)'
                   when :validation
                     ' (Validation Cases)'
                   when :reader_testing
                     ' (Reader Testing Cases)'
                   end
  end

  member_action :session_summary_report, :method => :get do
    @sessions = [Session.find(params[:id])]
    @cases_counts = cases_counts(@sessions)
    @reader_cases = reader_cases(@sessions)

    render 'admin/sessions/summary_report'
  end
  collection_action :summary_report, :method => :get do
    @sessions = scoped_collection
    @cases_counts = cases_counts(@sessions)
    @reader_cases = reader_cases(@sessions)
  end
  action_item :edit, :only => :index do
    link_to 'Summary', summary_report_admin_sessions_path
  end
  action_item :edit, :only => :show do
    link_to 'Summary', session_summary_report_admin_session_path(session)
  end
  action_item :edit, :only => :show do
    link_to 'Config Summary', config_summary_report_admin_session_path(session)
  end
  action_item :edit, :only => :config_summary_report do
    link_to 'Validation Cases', config_summary_report_admin_session_path(session, :case_flag => 'validation') unless params[:case_flag] == 'validation'
  end
  action_item :edit, :only => :config_summary_report do
    link_to 'Regular Cases', config_summary_report_admin_session_path(session, :case_flag => 'regular') if params[:case_flag] == 'validation'
  end

  member_action :deep_clone, :method => :post do
    @session = Session.find(params[:id])
    authorize! :read, @session

    new_study = Study.find(params[:session][:study_id])
    authorize! :manage, new_study

    new_session_name = params[:session][:name]

    components = []
    components << :forms if params[:session]['Components to clone'].include?('Forms')
    components << :cases if params[:session]['Components to clone'].include?('Cases')
    components << :patients if (params[:session]['Components to clone'].include?('Patients') || params[:session]['Components to clone'].include?('Cases'))
    components << :readers if params[:session]['Components to clone'].include?('Readers')
    components << :validators if params[:session]['Components to clone'].include?('Validators')

    new_session = @session.deep_clone(new_session_name, new_study, current_user, components)

    redirect_to(admin_session_path(new_session), :notice => 'Session successfully cloned')
  end
  member_action :deep_clone_form, :method => :get do
    @session = Session.find(params[:id])
    authorize! :read, @session

    @page_title = 'Clone Session'
  end
  action_item :edit, :only => :show do
    link_to('Clone', deep_clone_form_admin_session_path(resource)) if can? :read, resource
  end

  action_item :edit, :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'session', :audit_trail_view_id => resource.id))
  end

  member_action :reorder_case_list, :method => :post do
    @session = Session.find(params[:id])

    new_case_list = params[:case_list].split(',')
    
    cases = new_case_list.map {|c| Case.find(c.to_i)}

    available_positions = cases.map {|c| c.position}.sort
    next_free_position = @session.next_position

    Case.transaction do
      # first we set the position to some unused position, so it won't clash with existing positions when setting the correct one next
      cases.each do |c|
        c.position = next_free_position
        c.save
        next_free_position += 1
      end
 
      cases.each do |c|
        c.position = available_positions.shift
        c.save
      end
    end

    redirect_to({:action => :show}, :notice => "The case list was successfully reordered")
  end
  member_action :reorder_case_list_form, :method => :get do
    @session = Session.find(params[:id])

    @page_title = 'Reorder Case List'
    @cases = @session.cases.where(:state => Case::state_sym_to_int(:unread))
  end
end
