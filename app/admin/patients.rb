require 'aa_customizable_default_actions'
require 'aa_domino'
require 'aa_erica_keywords'

ActiveAdmin.register Patient do
  menu(parent: 'store', priority: 20)

  actions :index, :show if Rails.application.config.is_erica_remote

  config.per_page = 100
  config.sort_order = 'centers.code_asc'

  controller do
    def max_csv_records
      1_000_000
    end

    def scoped_collection
      if(session[:selected_study_id].nil?)
        end_of_association_chain.includes(:center)
      else
        end_of_association_chain.includes(:center).where('centers.study_id' => session[:selected_study_id])
      end
    end

    def generate_selected_filters
      selected_filters = []

      selected_filters += Patient.accessible_by(current_ability).where(:id => params[:q][:id_in]).map {|patient| {:id => 'patient_'+patient.id.to_s, :text => patient.name, :type => 'patient'} } unless(params[:q][:id_in].nil?)
      selected_filters += Center.accessible_by(current_ability).where(:id => params[:q][:center_id_in]).map {|center| {:id => 'center_'+center.id.to_s, :text => center.code + ' - ' + center.name, :type => 'center'} } unless(params[:q][:center_id_in].nil?)
      selected_filters += Study.accessible_by(current_ability).where(:id => params[:q][:center_study_id_in]).map {|study| {:id => 'study_'+study.id.to_s, :text => study.name, :type => 'study'} } unless(params[:q][:center_study_id_in].nil?)

      return selected_filters
    end

    before_filter :authorize_erica_remote, only: :index, if: -> { ERICA.remote? }
    def authorize_erica_remote
      return if params[:format].blank?
      authorize! :download_status_files, Patient
    end

    before_filter :transform_filter_params, only: :index
    def transform_filter_params
      session[:current_images_filter] = nil if params[:clear_filter] == 'true'

      if params[:q] && params[:q][:center_id_in] == [""]
        params[:q].delete(:center_id_in)
        params[:q][:center_id_in] = session[:current_images_filter] if session[:current_images_filter].present?
      elsif params[:q].nil? || params[:q][:center_id_in].nil?
        params[:q] = {} if params[:q].nil?
        params[:q][:center_id_in] = session[:current_images_filter] if session[:current_images_filter].present?
      elsif params[:q] &&
            params[:q][:center_id_in].respond_to?(:length) &&
            params[:q][:center_id_in].length == 1 &&
            params[:q][:center_id_in][0].include?(',')
        params[:q][:center_id_in] = params[:q][:center_id_in][0].split(',')
      end
      session[:current_images_filter] = params[:q][:center_id_in] if params[:q].andand[:center_id_in]

      if params[:q] && params[:q][:center_id_in].respond_to?(:each)
        center_id_in = []

        params[:q][:center_id_in].each do |id|
          if(id =~ /^center_([0-9]*)/)
            center_id_in ||= []
            center_id_in << $1
          elsif(id =~ /^study_([0-9]*)/)
            params[:q][:center_study_id_in] ||= []
            params[:q][:center_study_id_in] << $1
          elsif(id =~ /^patient_([0-9]*)/)
            params[:q][:id_in] ||= []
            params[:q][:id_in] << $1
          elsif(id =~ /^([0-9]*)/)
            center_id_in << $1
          end
        end

        params[:q][:center_id_in] = center_id_in
      end
    end
  end

  # this is a "fake" sidebar entry, which is only here to ensure that our data array for the advanced patient filter is rendered to the index page, even if it is empty
  # the resulting sidebar is hidden by the advanced filters javascript
  sidebar :advanced_filter_data, :only => :index do
     render :partial => 'admin/shared/advanced_filter_data', :locals => {:selected_filters => controller.generate_selected_filters, :filter_select2_id => 'center_id'}
  end

  index do
    selectable_column
    column :center, :sortable => 'centers.code'
    column :subject_id
    keywords_column(:tags, 'Keywords') if Rails.application.config.is_erica_remote

    customizable_default_actions(current_ability)
  end

  show do |patient|
    attributes_table do
      row :center
      row :subject_id
      domino_link_row(patient)
      row :image_storage_path
      keywords_row(patient, :tags, 'Keywords') if Rails.application.config.is_erica_remote
      row :patient_data_raw do
        CodeRay.scan(JSON::pretty_generate(patient.data || {}), :json).div(:css => :class).html_safe
      end
    end
    active_admin_comments if can?(:comment, patient)
  end

  form do |f|
    f.inputs 'Details' do
      f.object.center_id = params[:center_id] if params.key?(:center_id)

      centers = Center.accessible_by(current_ability).order(:name, :id)
      if f.object.persisted?
        centers = centers.of_study(f.object.study.id)
      elsif session[:selected_study_id].present?
        centers = centers.of_study(session[:selected_study_id])
      end
      f.input(
        :center,
        collection: centers,
        # include_blank: false,
        input_html: {
          class: 'initialize-select2',
          'data-placeholder': 'Select a Center'
        }
      )

      f.input :subject_id, :hint => (f.object.persisted? ? 'Do not change this unless you are absolutely sure you know what you do. This can lead to problems in project management, because the Subject ID is used to identify patients across documents.' : '')
    end

    if f.object.new_record?
      templates =
        if session[:selected_study_id].present?
          Study.find(session[:selected_study_id]).visit_templates
        else
          f.object.study.andand.visit_templates
        end
      render(
        partial: 'visit_templates',
        locals: {
          selected_study: session[:selected_study_id],
          preselect: f.object.visit_template,
          templates: templates,
          allow_clear: true,
          create_patient: true
        }
      )
    end

    f.actions
  end

  # filters
  filter :center, :collection => []
  filter :subject_id, :label => 'Subject ID'
  keywords_filter(:tags, 'Keywords') if Rails.application.config.is_erica_remote

  action_item :audit_trail, only: :show, if: -> { can?(:read, Version) } do
    url = admin_versions_path(
      audit_trail_view_type: 'patient',
      audit_trail_view_id: resource.id
    )
    link_to('Audit Trail', url)
  end

  controller do
    def export_patients_for_ericav1(export_folder, patient_ids)
      background_job = BackgroundJob.create(:name => 'Export '+patient_ids.size.to_s+' Patients for ERICAv1 to '+export_folder, :user_id => current_user.id)

      PatientReadExportWorker.perform_async(background_job.id.to_s, export_folder, patient_ids)

      return background_job
    end

    def start_download_images(patient_id)
      patient = Patient.find(patient_id)
      authorize! :download_images, patient

      background_job = BackgroundJob.create(:name => "Download images for patient #{patient.name}", :user_id => current_user.id)

      DownloadImagesWorker.perform_async(background_job.id.to_s, 'Patient', patient_id)

      return background_job
    end
  end

  member_action :download_images, :method => :get do
    background_job = start_download_images(params[:id])
    redirect_to admin_background_job_path(background_job), :notice => 'Your download will be available shortly. Please refresh this page to see whether it is available yet.'
  end
  action_item :download_images, :only => :show do
    link_to('Download images', download_images_admin_patient_path(resource)) if can? :download_images, resource
  end

  collection_action :batch_export_for_ericav1, :method => :post do
    if(params[:export_folder].blank?)
      flash[:error] = 'You have to specify an export folder.'
      if(params[:return_url].blank?)
        redirect_to admin_patients_path
      else
        redirect_to params[:return_url]
      end
      return
    end

    patient_ids = params[:patients].split(' ')

    background_job = export_patients_for_ericav1(params[:export_folder], patient_ids)
    redirect_to admin_background_job_path(background_job), :notice => 'The export was started successfully.'
  end
  member_action :export_for_ericav1, :method => :get do
    @page_title = 'Export for ERICAv1'
    render 'admin/patients/export_for_ericav1_form', :locals => {:selection => [resource.id.to_s], :return_url => request.referer}
  end
  action_item :export_for_erica1, :only => :show do
    link_to('Export for ERICAv1', export_for_ericav1_admin_patient_path(resource)) if can? :manage, resource
  end
  batch_action :export_for_ericav1, if: proc {can? :manage, Patient} do |selection|
    @page_title = 'Export for ERICAv1'
    render 'admin/patients/export_for_ericav1_form', :locals => {:selection => selection, :return_url => request.referer}
  end

  member_action :reorder_visits, :method => :post do
    @patient = Patient.find(params[:id])

    new_visits_list = params[:new_visits_list].split(',')

    visits = new_visits_list.map {|v| Visit.find(v.to_i)}

    available_visit_numbers = visits.map {|v| v.visit_number}.sort
    next_free_visit_number = (@patient.visits.empty? ? 0 : @patient.visits.order('visit_number desc').first.visit_number+1)

    Visit.transaction do
      # first we set the visit_number to some unused number, so it won't clash with existing visit numbers when setting the correct one next
      visits.each do |v|
        v.visit_number = next_free_visit_number
        v.save
        next_free_visit_number += 1
      end

      visits.each do |v|
        v.visit_number = available_visit_numbers.shift
        v.save
      end
    end

    redirect_to({:action => :show}, :notice => "The visits was successfully reordered")
  end
  member_action :reorder_visits_form, :method => :get do
    @patient = Patient.find(params[:id])

    @page_title = 'Reorder Visits'
    @visits = @patient.visits
  end
  action_item :reorder_visits, :only => :show do
    link_to('Reorder Visits', reorder_visits_form_admin_patient_path(resource)) unless(resource.visits.empty? or cannot? :manage, resource)
  end

  collection_action :visit_templates, method: :get do
    @center = Center.find(params[:center_id])
    templates = @center.study.visit_templates
    enforced = (templates || {}).select { |name, tpl| tpl['create_patient_enforce'] }
    if enforced.empty?
      allowed = @center.hierarchy_grants?(
        user: current_user,
        activity: %i(create create_from_template),
        subject: Visit
      )
      render json: allowed ? templates : {}
    else
      render json: enforced.to_hash
    end
  end

  member_action :perform_create_visits_from_template, method: :post do
    @page_title = 'Create Visits'
    # TODO: Refactor using trailblazer, command objects or similar.
    authorize!(:create_from_template, Visit)
    @patient = Patient.find(params[:id])
    @template = params[:patient].andand[:visit_template]
    if @template.blank?
      flash[:error] = 'Please provide a visit template.'
    elsif !@patient.visit_template_applicable?(@template)
      flash[:error] = 'Visits with the same visit number for this patient already exist and selected visit template is not repeatable.'
    else
      @patient.create_visits_from_template!(@template)
      flash[:notice] = 'Visits created successfully.'
      return redirect_to(admin_patient_path(@patient))
    end
    @templates = @patient.study.andand.visit_templates
    render(:create_visits_from_template)
  end
  member_action :create_visits_from_template, method: :get do
    @page_title = 'Create Visits'
    authorize!(:create_from_template, Visit)
    @patient = Patient.find(params[:id])
    @templates = @patient.study.andand.visit_templates
  end
  action_item :create_visits_from_template, only: :show, if: -> { !resource.study.visit_templates.blank? } do
    link_to('Visits From Template', create_visits_from_template_admin_patient_path(resource))
  end

  viewer_cartable(:patient)
  erica_keywordable(:tags, 'Keywords') if Rails.application.config.is_erica_remote
end
