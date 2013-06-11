require 'aa_domino'

ActiveAdmin.register Visit do

  config.per_page = 100

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
    visit.remove_orphaned_required_series

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

  member_action :tqc_results, :method => :get do
    @visit = Visit.find(params[:id])

    @required_series_name = params[:required_series_name]
    if(@required_series_name.nil?)
      flash[:error] = 'Must specify the name of a required series.'
      redirect_to :action => :show
      return
    end
    @required_series = RequiredSeries.new(@visit, @required_series_name)

    tqc_spec = @required_series.tqc_spec_with_results
    if(tqc_spec.nil?)
      flash[:error] = 'Viewing tQC results requires a valid study config containing tQC specifications for this required series and existing tQC results.'
      redirect_to :action => :show
      return
    end

    @dicom_tqc_spec, @manual_tqc_spec = tqc_spec.partition {|spec| spec['type'] == 'dicom'}

    @page_title = "tQC results for #{@required_series.name}"
    render 'admin/visits/tqc_results'
  end
  member_action :tqc, :method => :post do
    @visit = Visit.find(params[:id])

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

    success = @visit.set_tqc_result(required_series_name, tqc_result, current_user)
    if(success == true)
      redirect_to({:action => :show}, :notice => 'tQC results saved.')
    else
      flash[:error] = 'Storing tQC results failed: '+sucess
      redirect_to :action => :show
    end
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

    tqc_spec = @required_series.tqc_spec
    if(tqc_spec.nil?)
      flash[:error] = 'Performing tQC requires a valid study config containing tQC specifications for this required series.'
      redirect_to :action => :show
      return
    end

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

  controller do
    def perform_dicom_tqc_check(expected, actual)
      return nil if actual.nil?

      actual_as_numeric = begin Float(actual) rescue nil end

      result = false
      if(expected.is_a?(Array))        
        expected.each do |allowed_value|
          if(allowed_value.is_a?(Numeric) and not actual_as_numeric.nil?)
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

    redirect_to viewer_admin_image_series_path(@required_series.assigned_image_series)
  end
  member_action :required_series_dicom_metadata, :method => :get do
    @visit = Visit.find(params[:id])

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
  action_item :only => :tqc_form do
    link_to('Open Viewer', required_series_viewer_admin_visit_path(resource, :required_series_name => params[:required_series_name]), :target => '_blank') unless params[:required_series_name].nil?
  end
  action_item :only => :tqc_form do
    link_to('DICOM Metadata', required_series_dicom_metadata_admin_visit_path(resource, :required_series_name => params[:required_series_name]), :target => '_blank') unless params[:required_series_name].nil?
  end
  
  viewer_cartable(:visit)
end
