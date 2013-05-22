require 'aa_domino'

ActiveAdmin.register Visit do

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :patient
    column :visit_number
    column :visit_type
    column :visit_date
    
    default_actions
  end

  show do |visit|
    attributes_table do
      row :patient
      row :visit_number
      row :visit_type
      row :visit_date
      domino_link_row(visit)
      row :image_storage_path
    end

    required_series_objects = visit.required_series_objects
    render :partial => 'admin/visits/required_series', :locals => { :visit => visit, :required_series => required_series_objects} unless required_series_objects.empty?
  end

  form do |f|
    f.inputs 'Details' do
      f.input :patient, :collection => (f.object.persisted? ? f.object.study.patients : Patient.all), :include_blank => (not f.object.persisted?)
      f.input :visit_number, :hint => (f.object.persisted? ? nil : 'A visit type can only be assigned once the visit was created. Please click on "Edit Visit" after this step to assign a visit type.')
      if(f.object.persisted?)
        f.input :visit_type, :collection => (f.object.study.nil? ? [] : f.object.study.visit_types), :include_blank => false
      end
      f.form_buffers.last # https://github.com/gregbell/active_admin/pull/965
    end

    f.buttons
  end

  # filters
  filter :patient
  filter :visit_number
  filter :visit_type

  member_action :assign_required_series, :method => :post do
    @visit = Visit.find(params[:id])

    @assignments = params[:assignments] || {}

    @visit.change_required_series_assignment(@assignments)

    redirect_to({:action => :show}, :notice => 'Assignments of required series changed.')
  end
  member_action :assign_required_series_form, :method => :get do
    @visit = Visit.find(params[:id])

    @required_series_names = params[:required_series_names]
    if(@required_series_names.nil?)
      @required_series_names = @visit.required_series_names
    else
      @required_series_names = @required_series_names.split(',')
    end
    @current_assignment = (@visit.visit_data.nil? ? {} : @visit.assigned_required_series_id_map)

    @page_title = 'Assign image series as required series'
    render 'admin/visits/assign_required_series'
  end
  action_item :only => :show do
    link_to('Assign Required Series', assign_required_series_form_admin_visit_path(resource))
  end
  
  viewer_cartable(:visit)
end
