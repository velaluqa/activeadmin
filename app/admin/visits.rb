require 'aa_domino'
require 'aa_erica_keywords'

ActiveAdmin.register Visit do
  decorate_with(VisitDecorator)

  menu(parent: 'store', priority: 40)

  actions :index, :show if Rails.application.config.is_erica_remote

  config.per_page = 100

  permit_params(
    :patient_id,
    :visit_number,
    :description,
    :visit_type,
    :state,
    :domino_unid,
    :patient,
    :assigned_image_series_index,
    :required_series,
    :mqc_date,
    :mqc_user_id,
    :mqc_state,
    :mqc_user,
    :mqc_results
  )

  controller do
    skip_load_and_authorize_resource(
      only: [
        :assign_required_series,
        :assign_required_series_form,
        :tqc_results,
        :tqc,
        :tqc_form,
        :mqc_results,
        :mqc,
        :mqc_form,
        :required_series_viewer,
        :required_series_dicom_metadata,
        :all_required_series_viewer,
        :webviewer,
        :viewer
      ]
    )

    def max_csv_records
      1_000_000
    end

    def scoped_collection
      if(session[:selected_study_id].nil?)
        end_of_association_chain.includes(:patient => :center)
      else
        end_of_association_chain.includes(:patient => :center).where('centers.study_id' => session[:selected_study_id])
      end
    end

    def generate_selected_filters
      selected_filters = []

      selected_filters += Visit.accessible_by(current_ability).where(:id => params[:q][:id_in]).map {|visit| {:id => 'visit_'+visit.id.to_s, :text => visit.name, :type => 'visit'} } unless(params[:q][:id_in].nil?)
      selected_filters += Patient.accessible_by(current_ability).where(:id => params[:q][:patient_id_in]).map {|patient| {:id => 'patient_'+patient.id.to_s, :text => patient.name, :type => 'patient'} } unless(params[:q][:patient_id_in].nil?)
      selected_filters += Center.accessible_by(current_ability).where(:id => params[:q][:patient_center_id_in]).map {|center| {:id => 'center_'+center.id.to_s, :text => center.code + ' - ' + center.name, :type => 'center'} } unless(params[:q][:patient_center_id_in].nil?)
      selected_filters += Study.accessible_by(current_ability).where(:id => params[:q][:patient_center_study_id_in]).map {|study| {:id => 'study_'+study.id.to_s, :text => study.name, :type => 'study'} } unless(params[:q][:patient_center_study_id_in].nil?)

      return selected_filters
    end

    before_action :authorize_erica_remote, only: :index, if: -> { ERICA.remote? }
    def authorize_erica_remote
      return if params[:format].blank?
      authorize! :download_status_files, Visit
    end

    before_action :transform_filter_params, only: :index
    def transform_filter_params
      session[:current_images_filter] = nil if params[:clear_filter] == 'true'

      if params[:q] && params[:q][:patient_id_in] == [""]
        params[:q].delete(:patient_id_in)
        params[:q][:patient_id_in] = session[:current_images_filter] if session[:current_images_filter].present?
      elsif params[:q].nil? || params[:q][:patient_id_in].nil?
        params[:q] ||= {}
        params[:q][:patient_id_in] = session[:current_images_filter] if session[:current_images_filter].present?
      elsif params[:q] &&
            params[:q][:patient_id_in].respond_to?(:length) &&
            params[:q][:patient_id_in].length == 1 &&
            params[:q][:patient_id_in][0].include?(',')
        params[:q][:patient_id_in] = params[:q][:patient_id_in][0].split(',')
      end
      session[:current_images_filter] = params[:q][:patient_id_in] if params[:q].andand[:patient_id_in]

      if params[:q] && params[:q][:patient_id_in].respond_to?(:each)
        patient_id_in = []

        params[:q][:patient_id_in].each do |id|
          if id =~ /^center_([0-9]*)/
            params[:q][:patient_center_id_in] ||= []
            params[:q][:patient_center_id_in] << $1
          elsif id =~ /^study_([0-9]*)/
            params[:q][:patient_center_study_id_in] ||= []
            params[:q][:patient_center_study_id_in] << $1
          elsif id =~ /^patient_([0-9]*)/
            patient_id_in << $1
          elsif id =~ /^visit_([0-9]*)/
            params[:q][:id_in] ||= []
            params[:q][:id_in] << $1
          elsif id =~ /^([0-9]*)/
            patient_id_in << $1
          end
        end

        params[:q][:patient_id_in] = patient_id_in
      end
    end
  end

  # this is a "fake" sidebar entry, which is only here to ensure that our data array for the advanced patient filter is rendered to the index page, even if it is empty
  # the resulting sidebar is hidden by the advanced filters javascript
  sidebar :advanced_filter_data, :only => :index do
    render :partial => 'admin/shared/advanced_filter_data', :locals => {:selected_filters => controller.generate_selected_filters, :filter_select2_id => 'patient_id'}
  end

  index do
    selectable_column
    column :patient, sortable: 'patients.subject_id' do |visit|
      link_to(visit.patient.name, admin_patient_path(visit.patient))
    end
    column :visit_number
    column :description
    column :visit_type
    column :visit_date, sortable: false
    column :state, :sortable => :state
    if can? :read_mqc, Visit
      column 'mQC State', :mqc_state, :sortable => :mqc_state do |visit|
        next unless can? :read_mqc, visit

        case(visit.mqc_state_sym)
        when :pending then status_tag('Pending')
        when :issues then status_tag('Performed, issues present', class: 'error')
        when :passed then status_tag('Performed, passed', class: 'ok')
        end
      end
      column 'mQC Date', :mqc_date do |visit|
        next unless can? :read_mqc, visit

        pretty_format(visit.mqc_date)
      end
      column 'mQC User', :mqc_user, :sortable => :mqc_user_id do |visit|
        next unless can? :read_mqc, visit
        next if visit.mqc_user.nil?

        link_to(visit.mqc_user.name, admin_user_path(visit.mqc_user))
      end 
    end
    tags_column(:tags, 'Tags') if can?(:read_tags, Visit)

    customizable_default_actions(current_ability)
  end

  hideable_columns(
    columns: [
      :patient,
      :visit_number,
      :description,
      :visit_type,
      :visit_date,
      :state,
      :mqc_state,
      :mqc_date,
      :mqc_user,
      :tags
    ]
  )

  show do |visit|
    attributes_table do
      row :patient
      row :visit_number
      row :description
      row :visit_type
      row :visit_date
      row :state
      if can? :read_mqc, visit
        row 'mQC State', &:mqc_state
        row :mqc_configuration if visit.mqc_version
      end
      tags_row(visit, :tags, 'Tags', can?(:update_tags, visit))
      domino_link_row(visit)
      row :image_storage_path
    end

    _, order, direction = params[:order].andand.match(/^(.+)_(.+)/).to_a
    required_series =
      if order.present?
        visit.required_series.order(order => direction)
      else
        visit.required_series
      end

    panel 'Required Series' do
      if !visit.study.semantically_valid?
        text_node "The study configuration is not valid."
      elsif visit.visit_type.nil?
        text_node "Assign a visit type to manage required series."
      elsif !visit.visit_type_valid?
        text_node "Assigned visit type not found in study configuration. Maybe the study configuration changed in the meantime. Reassign a valid visit type to manage required series."
      elsif !visit.required_series_available?
        text_node "The study configuration does not provide any required series for this visit type."
      elsif required_series.empty?
        text_node "No required series found."
      else
        render(
          partial: 'admin/visits/required_series',
          locals: {
            visit: visit,
            required_series: required_series
          }
        )
      end
    end

    active_admin_comments if can?(:comment, visit)
  end

  form do |f|
    if f.object.original_visit_number.present? && f.object.repeatable_count.present?
      # ActiveAdmin is asking for `f.object[:visit_number]` which
      # holds only the integer value, not the concatenation of
      # `Visit#visit_number`. Thus - as a work around - we set it
      # explicitly.
      # TODO: Find a cleaner way solve this.
      f.object[:visit_number] = f.object.visit_number
    end
    visit_types =
      if(f.object.persisted? and not f.object.study.nil?)
        f.object.study.visit_types
      elsif(not session[:selected_study_id].nil?)
        Study.find(session[:selected_study_id]).visit_types
      else
        nil
      end
    f.object.patient_id = params[:patient_id] if params.key?(:patient_id)
    f.inputs 'Details' do
      patients = Patient.accessible_by(current_ability).order(:subject_id, :id)
      if f.object.persisted?
        patients = patients.joins(:center).where(centers: { study_id: f.object.study.id })
      elsif session[:selected_study_id].present?
        patients = patients.joins(:center).where(centers: { study_id: session[:selected_study_id] })
      end
      f.input(
        :patient,
        collection: patients,
        input_html: {
          class: 'initialize-select2',
          'data-placeholder': 'Select a Patient'
        }
      )
      f.input :visit_number, :hint => (visit_types.nil? ? 'A visit type can only be assigned once the visit was created. Please click on "Edit Visit" after this step to assign a visit type.' : nil)
      f.input :description
      unless(visit_types.nil?)
        f.input(
          :visit_type,
          collection: visit_types,
          input_html: {
            class: 'initialize-select2',
            'data-placeholder': 'none'
          }
        )
      end
    end

    f.actions
  end

  csv do
    column :id
    column :visit_number
    column :visit_type
    column :created_at
    column :updated_at
    column :description
    column('State') { |v| can?(:read_mqc, v) ? v.state_sym : '' }
    column('Mqc Date') { |v| can?(:read_mqc, v) ? v.mqc_date : '' }
    column('Mqc State') { |v| can?(:read_mqc, v) ? v.mqc_state_sym : '' }
    column('Patient') { |v| v.patient.nil? ? '' : v.patient.name }
    column('Visit Date') { |v| v.visit_date }
  end

  # filters
  filter :patient, :collection => [], input_html: { class: "no-auto-select2"}
  filter :visit_number
  filter :description
  filter :visit_type
  tags_filter(:tags, 'Tags')

  member_action :assign_required_series, :method => :post do
    @visit = Visit.find(params[:id])
    authorize! :assign_required_series, @visit

    @assignments = params[:assignments] || {}

    @visit.change_required_series_assignment(@assignments)

    redirect_to({:action => :show}, :notice => 'Assignments of required series changed.')
  end
  member_action :assign_required_series_form, :method => :get do
    @visit = Visit.find(params[:id])
    authorize! :assign_required_series, @visit

    @required_series_names = params[:required_series_names].andand.split(',') || @visit.required_series_names
    if(@required_series_names.blank?)
      flash[:error] = 'The associated visit has no required series. This could be due to an invalid study config, no assigned visit type or an empty visit type.'
      redirect_back(fallback_location: admin_visit_path(id: params[:id]))
      return
    end

    @required_series_names = params[:required_series_names].andand.split(',')
    @required_series_names ||= @visit.required_series_names
    @required_series_names = @visit.required_series_names & @required_series_names

    if @required_series_names.blank?
      flash[:error] = 'This visit does not have required series specified by the given parameter.'

      redirect_back(fallback_location: admin_visit_path(id: params[:id]))
      return
    end

    @required_series_names = params[:required_series_names].andand.split(',')
    @required_series_names ||= @visit.required_series_names
    @required_series_names = @visit.required_series_names & @required_series_names

    if @required_series_names.blank?
      flash[:error] = 'This visit does not have required series specified by the given parameter.'

      redirect_back(fallback_location: admin_visit_path(id: params[:id]))
      return
    end

    @current_assignment = @visit.required_series_assignment

    @page_title = 'Assign image series as required series'
    render 'admin/visits/assign_required_series'
  end
  action_item :assign_required_series, :only => :show, if: -> { can?(:assign_required_series, resource)} do
    link_to('Assign Required Series', assign_required_series_form_admin_visit_path(resource))
  end

  member_action :tqc_results, :method => :get do
    @visit = Visit.find(params[:id])
    authorize! :read_tqc, @visit

    @required_series_name = params[:required_series_name]
    if(@required_series_name.nil?)
      flash[:error] = 'Must specify the name of a required series.'
      redirect_to :action => :show
      return
    end
    @required_series = RequiredSeries.where(visit: @visit, name: @required_series_name).first

    tqc_spec = @required_series.tqc_spec_with_results
    if(tqc_spec.nil?)
      flash[:error] = 'Viewing tQC results requires a valid study config containing tQC specifications for this required series and existing tQC results.'
      redirect_to :action => :show
      return
    end

    @tqc_version = if @required_series.tqc_version
                     @required_series.tqc_version
                   elsif @visit.study.andand.locked_version
                     @visit.study.locked_version
                   else
                     nil
                   end

    @dicom_tqc_spec, @manual_tqc_spec = tqc_spec.partition {|spec| spec['type'] == 'dicom'}

    @page_title = "tQC results for #{@required_series.name}"
    render 'admin/visits/tqc_results'
  end
  member_action :tqc, :method => :post do
    @visit = Visit.find(params[:id])
    authorize! :perform_tqc, @visit

    required_series_name = params[:required_series_name]
    if(required_series_name.nil?)
      flash[:error] = 'Must specify the name of a required series.'
      redirect_to :action => :show
      return
    end

    tqc_result = {}
    unless(params[:tqc_result].nil?)
      params[:tqc_result].each do |id, value|
        tqc_result[id] = (value == '1')
      end
    end

    success = @visit.set_tqc_result(required_series_name, tqc_result, current_user, params[:tqc_comment])
    if(success == true)
      redirect_to({:action => :show}, :notice => 'tQC results saved.')
    else
      flash[:error] = 'Storing tQC results failed: '+sucess
      redirect_to :action => :show
    end
  end
  member_action :tqc_form, :method => :get do
    @visit = Visit.find(params[:id])
    authorize! :perform_tqc, @visit

    @required_series_name = params[:required_series_name]
    if(@required_series_name.nil?)
      flash[:error] = 'Must specify the name of a required series.'
      redirect_to :action => :show
      return
    end
    @required_series = RequiredSeries.where(visit: @visit, name: @required_series_name).first

    if(@required_series.assigned_image_series.nil? or @required_series.assigned_image_series.images.empty?)
      flash[:error] = 'tQC can only be performed once an image series (containing at least one image) has been assigned for this required series.'
      redirect_to :action => :show
      return
    end

    unless @visit.study.semantically_valid?
      flash[:error] = 'Performing tQC requires a valid study config containing tQC specifications for this required series.'
      redirect_to :action => :show
      return
    end
    tqc_spec = @required_series.tqc_spec

    @dicom_tqc_spec, @manual_tqc_spec = tqc_spec.partition {|spec| spec['type'] == 'dicom'}

    @dicom_image = @required_series.assigned_image_series.sample_image
    @dicom_metadata = (@dicom_image.nil? ? {} : @dicom_image.dicom_metadata[1])
    @dicom_tqc_spec.each do |dicom_tqc_spec|
      dicom_tqc_spec['actual_value'] = (@dicom_metadata[dicom_tqc_spec['dicom_tag']].nil? ? nil : @dicom_metadata[dicom_tqc_spec['dicom_tag']][:value])
      dicom_tqc_spec['result'] = perform_dicom_tqc_check(dicom_tqc_spec['expected'], dicom_tqc_spec['actual_value'])
    end

    @page_title = "Perform tQC for #{@required_series.name}"
    render 'admin/visits/tqc_form'
  end

  member_action :mqc_results, :method => :get do
    @visit = Visit.find(params[:id])
    authorize! :read_mqc, @visit

    mqc_version = @visit.mqc_version
    @mqc_spec = @visit.mqc_spec_with_results_at_version(mqc_version)
    if(@mqc_spec.nil?)
      flash[:error] = 'Viewing mQC results requires a valid study config containing mQC specifications for this visits visit type and existing mQC results.'
      redirect_to :action => :show
      return
    end

    @page_title = "mQC results"
    render 'admin/visits/mqc_results'
  end
  member_action :mqc, :method => :post do
    @visit = Visit.find(params[:id])
    authorize! :perform_mqc, @visit

    unless([:complete_tqc_passed, :complete_tqc_issues, :incomplete_na].include?(@visit.state_sym))
      flash[:error] = 'mQC cannot be performed for a visit in this state.'
      redirect_to :action => :show
      return
    end

    mqc_result = {}
    unless(params[:mqc_result].nil?)
      params[:mqc_result].each do |id, value|
        mqc_result[id] = (value == '1')
      end
    end

    success = @visit.set_mqc_result(mqc_result, current_user, params[:mqc_comment])
    if(success == true)
      redirect_to({:action => :show}, :notice => 'mQC results saved.')
    else
      flash[:error] = 'Storing mQC results failed: '+sucess
      redirect_to :action => :show
    end
  end
  member_action :mqc_form, :method => :get do
    @visit = Visit.find(params[:id])
    authorize! :perform_mqc, @visit

    unless([:complete_tqc_passed, :complete_tqc_issues, :incomplete_na].include?(@visit.state_sym))
      flash[:error] = 'mQC cannot be performed for a visit in this state.'
      redirect_to :action => :show
      return
    end

    @mqc_spec = @visit.locked_mqc_spec
    if(@mqc_spec.nil?)
      flash[:error] = 'Performing mQC requires a valid study config containing mQC specifications for this visits visit type.'
      redirect_to :action => :show
      return
    end

    @page_title = "Perform mQC"
    render 'admin/visits/mqc_form'
  end
  action_item :edit, only: :show, if: -> { resource.ready_for_mqc? && can?(:perform_mqc, resource) } do
    link_to('Perform mQC', mqc_form_admin_visit_path(resource))
  end

  action_item :edit, only: :show, if: -> { resource.has_mqc_results? && can?(:read_mqc, resource) } do
    link_to('mQC Results', mqc_results_admin_visit_path(resource))
  end

  member_action :edit_state, :method => :post do
    @visit = Visit.find(params[:id])
    authorize! :update_state, @visit

    @visit.state = params[:visit][:state]

    if @visit.save
      flash[:notice] = 'Visit state was changed successfully.'
    else
      flash[:error] = 'Visit state change failed.'
    end
    redirect_to params[:return_url]
  end

  member_action :edit_state_form, :method => :get do
    @visit = Visit.find(params[:id])
    authorize! :update_state, @visit

    @states = [['Incomplete, not available', :incomplete_na], ['Complete, tQC of all series passed', :complete_tqc_passed], ['Incomplete, queried', :incomplete_queried], ['Complete, tQC not finished', :complete_tqc_pending], ['Complete, tQC finished, not all series passed', :complete_tqc_issues]]

    @return_url = params[:return_url] || admin_visit_path(@visit)
    @page_title = 'Change Visit State'
  end
  action_item :edit, :only => :show, if: -> { can?(:update_state, resource) } do
    link_to('Change State', edit_state_form_admin_visit_path(resource, :return_url => request.fullpath))
  end

  controller do
    def perform_dicom_tqc_check(expected, actual)
      return nil if actual.nil?

      actual_as_numeric = begin Float(actual) rescue nil end

      result = false
      if(expected.is_a?(Array))
        expected.each do |allowed_value|
          if allowed_value.is_a?(Numeric) && actual_as_numeric.present?
            if(allowed_value == actual_as_numeric)
              result = true
              break
            end
          elsif(allowed_value.is_a?(String))
            if(allowed_value == actual)
              result = true
              break
            end
          end
        end
      else
        begin
          formula = (expected.is_a?(String) ? expected : 'x = '+expected.to_s)
          pp formula
          pp actual
          result = Dentaku(formula, {:x => actual_as_numeric})
        rescue Exception => e
          pp e
          result = false
        end
      end

      return result
    end
  end

  member_action :required_series_viewer, :method => :get do
    @visit = Visit.find(params[:id])
    authorize! :read, @visit

    @required_series_name = params[:required_series_name]
    if(@required_series_name.nil?)
      flash[:error] = 'Must specify the name of a required series.'
      redirect_to :action => :show
      return
    end
    @required_series = RequiredSeries.new(@visit, @required_series_name)

    if(@required_series.assigned_image_series.nil?)
      flash[:error] = 'There is no image series assigned to this required series.'
      redirect_to :action => :show
      return
    end

    redirect_to weasis_viewer_admin_image_series_path(@required_series.assigned_image_series)
  end
  member_action :required_series_dicom_metadata, :method => :get do
    @visit = Visit.find(params[:id])
    authorize! :read, @visit

    @required_series_name = params[:required_series_name]
    if(@required_series_name.nil?)
      flash[:error] = 'Must specify the name of a required series.'
      redirect_to :action => :show
      return
    end
    @required_series = RequiredSeries.new(@visit, @required_series_name)

    if(@required_series.assigned_image_series.nil? or @required_series.assigned_image_series.images.empty?)
      flash[:error] = 'There is no image series assigned to this required series or the assigned series contains no images.'
      redirect_to :action => :show
      return
    end

    redirect_to dicom_metadata_admin_image_series_path(@required_series.assigned_image_series)
  end
  action_item :maximize_window, :only => :tqc_form do
    link_to('Open Viewer', webviewer_admin_visit_path(resource, scope: params[:required_series_name]), :target => '_blank') unless params[:required_series_name].nil?
  end
  action_item :details, :only => :tqc_form do
    required_series = resource.required_series.where(name: params[:required_series_name]).first

    link_to('DICOM Metadata', dicom_metadata_admin_image_series_path(required_series.image_series), :target => '_blank') if required_series
  end

  member_action :viewer, method: :get do
    # authorize
    # Manually find the `resource` as active admin would otherwise
    # perform a lazy authorization causing an error:
    resource = Visit.find(params[:id])

    scope_query = Base64.strict_encode64(
      JSON.dump(
        visit_id: resource.id,
        series: params[:scope] || "all_rs"
      )
    )

    @router_basename = "/admin/visits/#{resource.id}"
    @wado_rs_endpoint = "#{request.base_url}/dicomweb/visit/#{scope_query}/rs"

    render "shared/dicom_viewer", layout: nil
  end

  member_action :webviewer, method: :get do
    scope_query = params[:scope] || "all_rs"

    # Manually find the `resource` as active admin would otherwise
    # perform a lazy authorization causing an error:
    resource = Visit.find(params[:id])
    required_series = resource.required_series.where(name: scope_query).first
    # authorize

    @page_title = case scope_query
                  when "all_rs" then "Assigned Required Series"
                  when "all" then "All Image Series"
                  else required_series.name
                  end
    render(
      'shared/_dicom_viewer_iframe',
      locals: {
        viewer_url: viewer_admin_visit_path(resource) + "/" + scope_query
      }
    )
  end

  member_action :all_required_series_viewer, :method => :get do
    @visit = Visit.find(params[:id])
    authorize! :read, @visit

    current_user.ensure_authentication_token!
    @wado_query_urls = [required_series_wado_query_visit_url(@visit, :format => :xml, :authentication_token => current_user.authentication_token)]

    name = @visit
             .name
             .gsub(/[^0-9A-Za-z.\-]/, '_')
             .gsub(/[()]/, '')
             .gsub(/_{2,}/, '_')
             .gsub(/_\z/, '')
             .gsub(/\A_/, '')
             .downcase
    send_data(
      render_to_string('admin/shared/viewer_weasis', formats: [:xml], :layout => false),
      type: 'application/x-java-jnlp-file',
      filename: "required_series_visit_#{name}.jnlp",
      disposition: 'attachment'
    )
  end

  action_item :maximize_window, :only => [:show, :mqc_form, :mqc_results] do
    link_to('Viewer (RS)', webviewer_admin_visit_path(resource, scope: "all_rs"), target: "_blank")
  end

  controller do
    def start_download_images(visit_id)
      visit = Visit.find(visit_id)
      authorize! :download_images, visit

      background_job = DownloadImagesWorker.perform_async(
        "Visit", params[:id],
        name: "Download images for visit #{visit.name}",
        user_id: current_user.id
      )
  
      return background_job
    end
  end
  member_action :download_images, :method => :get do
    background_job = start_download_images(params[:id])
    redirect_to admin_background_job_path(background_job), :notice => 'Your download will be available shortly.'
  end
  action_item :edit, :only => :show do
    link_to('Download images', download_images_admin_visit_path(resource)) if can? :download_images, resource
  end

  viewer_cartable(:visit)
  erica_taggable(:tags, 'Tags')

  action_item :audit_trail, only: :show, if: -> { can?(:read, Version) } do
    url = admin_versions_path(
      audit_trail_view_type: 'visit',
      audit_trail_view_id: resource.id
    )
    link_to('Audit Trail', url)
  end
end
