require 'aa_customizable_default_actions'
require 'aa_domino'

ActiveAdmin.register Patient do

  config.per_page = 100

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      if(session[:selected_study_id].nil?)
        end_of_association_chain.accessible_by(current_ability)
      else
        end_of_association_chain.accessible_by(current_ability).includes(:center).where('centers.study_id' => session[:selected_study_id])
      end
    end

    def generate_selected_filters
      selected_filters = []

      selected_filters += Patient.accessible_by(current_ability).where(:id => params[:q][:id_in]).map {|patient| {:id => 'patient_'+patient.id.to_s, :text => patient.name, :type => 'patient'} } unless(params[:q][:id_in].nil?)
      selected_filters += Center.accessible_by(current_ability).where(:id => params[:q][:center_id_in]).map {|center| {:id => 'center_'+center.id.to_s, :text => center.code + ' - ' + center.name, :type => 'center'} } unless(params[:q][:center_id_in].nil?)
      selected_filters += Study.accessible_by(current_ability).where(:id => params[:q][:center_study_id_in]).map {|study| {:id => 'study_'+study.id.to_s, :text => study.name, :type => 'study'} } unless(params[:q][:center_study_id_in].nil?)

      return selected_filters
    end

    def index
      session[:current_images_filter] = nil if(params[:clear_filter] == 'true')
      
      if(params[:q] and params[:q][:center_id_in] == [""])
        params[:q].delete(:center_id_in)

        params[:q][:center_id_in] = session[:current_images_filter] unless session[:current_images_filter].blank?
      elsif(params[:q].nil? or params[:q][:center_id_in].nil?)
        params[:q] = {} if params[:q].nil?
        params[:q][:center_id_in] = session[:current_images_filter] unless session[:current_images_filter].blank?
      elsif(params[:q] and
         params[:q][:center_id_in].respond_to?(:length) and
         params[:q][:center_id_in].length == 1 and
         params[:q][:center_id_in][0].include?(','))
        params[:q][:center_id_in] = params[:q][:center_id_in][0].split(',')
      end
      session[:current_images_filter] = params[:q][:center_id_in] unless params[:q].nil? or params[:q][:center_id_in].nil?

      if(params[:q] and params[:q][:center_id_in].respond_to?(:each)) 
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
          end
        end

        params[:q][:center_id_in] = center_id_in
      end
      pp params

      index!
    end
  end

  # this is a "fake" sidebar entry, which is only here to ensure that our data array for the advanced patient filter is rendered to the index page, even if it is empty
  # the resulting sidebar is hidden by the advanced filters javascript
  sidebar :advanced_filter_data, :only => :index do
     render :partial => 'admin/shared/advanced_filter_data', :locals => {:selected_filters => controller.generate_selected_filters, :filter_select2_id => 'center_id'}
  end

  index do
    selectable_column
    column :center, :sortabel => :center_id
    column :subject_id
    
    customizable_default_actions do |resource|
      (resource.cases.empty? and resource.form_answers.empty?) ? [] : [:destroy]
    end
  end

  show do |patient|
    attributes_table do
      row :center
      row :subject_id
      domino_link_row(patient)
      row :image_storage_path
      row :patient_data_raw do
        CodeRay.scan(JSON::pretty_generate(patient.patient_data.data), :json).div(:css => :class).html_safe unless patient.patient_data.nil?
      end
    end
  end

  form do |f|
    centers = (session[:selected_study_id].nil? ? Center.accessible_by(current_ability) : Study.find(session[:selected_study_id]).centers.accessible_by(current_ability))

    f.inputs 'Details' do
      f.input :center, :collection => (f.object.persisted? ? f.object.study.centers : centers), :include_blank => (not f.object.persisted?)
      f.input :subject_id, :hint => (f.object.persisted? ? 'Do not change this unless you are absolutely sure you know what you do. This can lead to problems in project management, because the Subject ID is used to identify patients across documents.' : '')
    end

    f.buttons
  end

  # filters
  filter :center, :collection => []
  filter :subject_id, :label => 'Subject ID'

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'patient', :audit_trail_view_id => resource.id))
  end

  controller do
    def export_patients_for_ericav1(export_folder, patient_ids)
      background_job = BackgroundJob.create(:name => 'Export '+patient_ids.size.to_s+' Patients for ERICAv1 to '+export_folder, :user_id => current_user.id)

      PatientReadExportWorker.perform_async(background_job.id.to_s, export_folder, patient_ids)

      return background_job
    end
  end

  collection_action :batch_export_for_ericav1, :method => :post do
    if(params[:export_folder].blank?)
      flash[:error] = 'You have to specify an export folder.'
      redirect_to admin_patients_path
      return
    end

    patient_ids = params[:patients].split(' ')

    background_job = export_patients_for_ericav1(params[:export_folder], patient_ids)
    redirect_to admin_background_job_path(background_job), :notice => 'The export was started successfully.'
  end
  member_action :export_for_ericav1, :method => :get do    
    @page_title = 'Export for ERICAv1'
    render 'admin/patients/export_for_ericav1_form', :locals => {:selection => [resource.id.to_s]}
  end
  action_item :only => :show do
    link_to('Export for ERICAv1', export_for_ericav1_admin_patient_path(resource))
  end
  batch_action :export_for_ericav1 do |selection|
    @page_title = 'Export for ERICAv1'
    render 'admin/patients/export_for_ericav1_form', :locals => {:selection => selection}
  end

  viewer_cartable(:patient)
end
