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
    
    required_series_spec = visit.required_series
    pp required_series_spec
    unless(required_series_spec.nil?)
      assigned_required_series = visit.assigned_required_series_map

      render :partial => 'admin/visits/required_series', :locals => { :visit => visit, :required_series_spec => required_series_spec, :assigned_required_series => assigned_required_series}
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :patient
      f.input :visit_number
      f.input :visit_type, :collection => (f.object.study.nil? ? [] : f.object.study.visit_types), :include_blank => false
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

    @visit.ensure_visit_data_exists
    visit_data = @visit.visit_data
    @assignments.each do |required_series_name, series_id|
      if(series_id.empty?)
        visit_data.assigned_required_series.delete(required_series_name)
      else
        visit_data.assigned_required_series[required_series_name] = series_id
      end
    end
    visit_data.save

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
    @current_assignment = (@visit.visit_data.nil? ? {} : @visit.visit_data.assigned_required_series)

    @page_title = 'Assign image series as required series'
    render 'admin/visits/assign_required_series'
  end
  action_item :only => :show do
    link_to('Assign Required Series', assign_required_series_form_admin_visit_path(resource))
  end
  
  viewer_cartable(:visit)
end
