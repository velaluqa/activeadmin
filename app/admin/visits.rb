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
    unless(params[:order].blank?)
      split_position = params[:order].rindex('_')

      unless(split_position.nil?)
        key, direction = params[:order][0..split_position-1], params[:order][split_position+1..-1]
        
        if(['name', 'image_series_id', 'tqc_date', 'tqc_user_id', 'tqc_state'].include?(key))
          required_series_objects.sort! do |a, b|
            a_val = a.instance_variable_get('@'+key)
            b_val = b.instance_variable_get('@'+key)
            
            if(a_val.nil? and b_val.nil?)
              0
            elsif(a_val.nil?)
              -1
            elsif(b_val.nil?)
              1
            else
              a_val <=> b_val
            end
          end
          required_series_objects.reverse! if (direction == 'desc')
        end
      end
    end
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

  member_action :tqc, :method => :post do
    @visit = Visit.find(params[:id])

    pp params[:tqc_result]

    redirect_to({:action => :show}, :notice => 'tQC results saved.')
  end
  member_action :tqc_form, :method => :get do
    @visit = Visit.find(params[:id])

    @required_series_name = params[:required_series_name]
    if(@required_series_name.nil?)
      flash[:error] = 'Must specify the name of a required series.'
      redirect_to :action => :show
      return
    end
    @required_series = RequiredSeries.new(@visit, @required_series_name)

    if(@required_series.assigned_image_series.nil? or @required_series.assigned_image_series.images.empty?)
      flash[:error] = 'tQC can only be performed once an image series (containing at least one image) has been assigned for this required series.'
      redirect_to :action => :show
      return
    end

    required_series_specs = @visit.required_series_specs
    if(required_series_specs.nil?)
      flash[:error] = 'Performing tQC requires a valid study config.'
      redirect_to :action => :show
      return
    end
    if(required_series_specs[@required_series_name].blank? or required_series_specs[@required_series_name]['tqc'].blank?)
      flash[:error] = 'The study configuration doesn\'t specify tQC for this required series.'
      redirect_to :action => :show
      return
    end

    tqc_spec = required_series_specs[@required_series_name]['tqc']
    @dicom_tqc_spec, @manual_tqc_spec = tqc_spec.partition {|spec| spec['type'] == 'dicom'}

    @dicom_image = @required_series.assigned_image_series.sample_image
    @dicom_metadata = (@dicom_image.nil? ? {} : @dicom_image.dicom_metadata[1])
    @dicom_tqc_spec.each do |dicom_tqc_spec|
      dicom_tqc_spec['actual_value'] = (@dicom_metadata[dicom_tqc_spec['dicom_tag']].nil? ? nil : @dicom_metadata[dicom_tqc_spec['dicom_tag']][:value])
      dicom_tqc_spec['result'] = if dicom_tqc_spec['actual_value'].nil?
                                   nil
                                 elsif dicom_tqc_spec['actual_value'] == dicom_tqc_spec['expected_value']
                                   true
                                 else
                                   false
                                 end
    end
    
    @page_title = "Perform tQC for #{@required_series.name}"
    render 'admin/visits/tqc_form'
  end
  
  viewer_cartable(:visit)
end
