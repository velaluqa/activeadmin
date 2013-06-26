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
    def export_patients_for_ericav1(export_folder, patients)
      case_list = []

      export_root_path = Pathname.new(Rails.application.config.image_export_root + '/' + export_folder)
      if(export_root_path.exist? and not export_root_path.directory?)
        raise 'The export target folder '+export_root_path.to_s+' exists, but isn\'t a folder.'
      end
      
      patients.each do |patient|
        patient_export_path = Pathname.new(export_root_path.to_s + '/' + patient.name)
        patient_export_path.rmtree if patient_export_path.exist?
        patient_export_path.mkpath
        
        patient.visits.each do |visit|
          next if visit.visit_number.blank?

          visit_export_path = Pathname.new(patient_export_path.to_s + '/' + visit.visit_number.to_s)
          visit_export_path.mkdir

          visit.required_series_objects.each do |required_series|
            next if required_series.assigned_image_series.nil?

            required_series_export_path = Pathname.new(visit_export_path.to_s + '/' + required_series.name)
            assigned_image_series_path = Pathname.new(required_series.assigned_image_series.absolute_image_storage_path)          

            required_series_export_path.make_symlink(assigned_image_series_path.relative_path_from(visit_export_path))
          end

          case_list << {:patient => patient.name, :images => visit.visit_number, :case_type => visit.visit_type}
        end
      end

      return case_list
    end
  end

  collection_action :batch_export_for_ericav1, :method => :post do
    if(params[:export_folder].blank?)
      flash[:error] = 'You have to specify an export folder.'
      redirect_to admin_patients_path
      return
    end

    patient_ids = params[:patients].split(' ')      
    patients = Patient.find(patient_ids)
    
    begin
      case_list = export_patients_for_ericav1(params[:export_folder], patients)
    rescue => e
      flash[:error] = e.message
      redirect_to admin_patients_path
      return
    end

    csv_options = {
      :col_sep => ',',
      :row_sep => :auto,
      :quote_char => '"',
      :headers => true,
      :converters => [:all, :date],
      :unconverted_fields => true,
    }    
    case_list_csv = CSV.generate(csv_options) do |csv|
      csv << ['patient', 'images', 'type']
      case_list.each do |c|
        csv << [c[:patient], c[:images], c[:case_type]]
      end
    end

    @page_title = 'Export Results'
    render 'admin/patients/export_for_ericav1_results', :locals => {:export_root => Rails.application.config.image_export_root + '/' + params[:export_folder], :case_list_csv => case_list_csv, :case_list_rows => case_list.size+1+1}
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
