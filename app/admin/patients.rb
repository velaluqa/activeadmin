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

    def generate_filter_options
      studies = if session[:selected_study_id].nil? then Study.accessible_by(current_ability) else Study.where(:id => session[:selected_study_id]).accessible_by(current_ability) end
      studies = studies.order('name asc')

      studies.map do |study|
        centers = study.centers.accessible_by(current_ability).order('code asc')
        
        centers_optgroups = centers.map do |center|
          {:id => "center_#{center.id.to_s}", :text => center.full_name}
        end

        {:id => "study_#{study.id.to_s}", :text => study.name, :children => centers_optgroups}
      end
    end
    def generate_filter_options_map(filter_options)
      filter_options_map = {}

      filter_options.each do |study|
        filter_options_map[study[:id]] = study[:text]

        study[:children].each do |center|
          filter_options_map[center[:id]] = center[:text]
        end
      end
      
      filter_options_map
    end
    def generate_selected_filters
      selected_filters = []

      selected_filters += params[:q][:center_id_in].map {|s_id| "center_#{s_id.to_s}"} unless(params[:q].nil? or params[:q][:center_id_in].nil?)
      selected_filters += params[:q][:center_study_id_in].map {|s_id| "study_#{s_id.to_s}"} unless(params[:q].nil? or params[:q][:center_study_id_in].nil?)

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
    filter_select2_data = controller.generate_filter_options
    filter_options_map = controller.generate_filter_options_map(filter_select2_data)
    render :partial => 'admin/shared/advanced_filter_data', :locals => {:filter_select2_data => filter_select2_data, :filter_options_map => filter_options_map, :selected_filters => controller.generate_selected_filters, :filter_select2_id => 'center_id'}
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

  viewer_cartable(:patient)
end
