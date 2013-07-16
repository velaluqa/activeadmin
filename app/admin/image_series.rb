require 'aa_domino'

ActiveAdmin.register ImageSeries do

  menu if: proc { can? :read, ImageSeries }

  scope :all, :default => true
  scope :not_assigned

  config.per_page = 100

  controller do
    load_and_authorize_resource :except => :index
    skip_load_and_authorize_resource :only => [:viewer, :dicom_metadata]

    def scoped_collection
      if(session[:selected_study_id].nil?)
        end_of_association_chain.accessible_by(current_ability).includes(:patient => :center)
      else
        end_of_association_chain.accessible_by(current_ability).includes(:patient => :center).where('centers.study_id' => session[:selected_study_id])
      end
    end

    def update
      image_series = ImageSeries.find(params[:id])
      currently_assigned_required_series_names = image_series.assigned_required_series
      original_visit = image_series.visit
      new_visit = (params[:image_series][:visit_id].blank? ? nil : Visit.find(params[:image_series][:visit_id]))

      if(params[:image_series][:visit_id].to_i == image_series.visit_id)
        params[:image_series].delete(:force_update)
        return update!
      end
      
      if(params[:image_series][:visit_id].to_i != image_series.visit_id and params[:image_series][:force_update] != 'true')
        if(original_visit and new_visit and original_visit.visit_type != new_visit.visit_type)
          flash[:error] = 'The new visit has a different visit type than the current visit. Therefore, this image series will lose all its assignments to required series of the current visit, including all tQC results. If you want to continue, press "Update" again.'
          redirect_to edit_admin_image_series_path(image_series, :force_update => true, :visit_id => params[:image_series][:visit_id])
          return
        end
        
        unless(new_visit.nil?)
          new_visit_assignment_map = new_visit.assigned_required_series_id_map
          already_assigned_required_series_names = []
          currently_assigned_required_series_names.each do |required_series_name|
            already_assigned_required_series_names << required_series_name unless new_visit_assignment_map[required_series_name].nil?
          end

          unless(already_assigned_required_series_names.empty?)
            flash[:error] = 'The following required series in the new visit will have their assignment and tQC results overwritten by this change: '+already_assigned_required_series_names.join(", ")+'. If you want to continue, press "Update" again.'
            redirect_to edit_admin_image_series_path(image_series, :force_update => true, :visit_id => params[:image_series][:visit_id])
            return
          end
        end
      end
      params[:image_series].delete(:force_update)

      original_required_series = (original_visit.nil? or original_visit.visit_data.nil? ? nil : original_visit.visit_data.required_series)

      original_visit_assignment_changes = {}
      new_visit_assignment_changes = {}
      currently_assigned_required_series_names.each do |required_series_name|
        original_visit_assignment_changes[required_series_name] = nil
        new_visit_assignment_changes[required_series_name] = image_series.id.to_s
      end
      original_visit.change_required_series_assignment(original_visit_assignment_changes) unless original_visit.nil?
      unless(original_visit.nil? or new_visit.nil? or original_visit.visit_type != new_visit.visit_type)
        new_visit.change_required_series_assignment(new_visit_assignment_changes)

        unless(original_required_series.nil?)
          currently_assigned_required_series_names.each do |required_series_name|
            next if original_required_series[required_series_name].nil?
            new_visit.set_tqc_result(required_series_name,
                                     original_required_series[required_series_name]['tqc_results'],
                                     original_required_series[required_series_name]['tqc_user_id'],
                                     original_required_series[required_series_name]['tqc_comment'],
                                     original_required_series[required_series_name]['tqc_date'],
                                     original_required_series[required_series_name]['tqc_version'])
          end
        end
      end
      
      update!
      puts 'YEEEHAAAA!!!'
    end

    def generate_selected_filters
      selected_filters = []

      
      selected_filters += Visit.accessible_by(current_ability).where(:id => params[:q][:visit_id_in]).map {|visit| {:id => 'visit_'+visit.id.to_s, :text => visit.name, :type => 'visit'} } unless(params[:q][:visit_id_in].nil?)
      selected_filters += Patient.accessible_by(current_ability).where(:id => params[:q][:patient_id_in]).map {|patient| {:id => 'patient_'+patient.id.to_s, :text => patient.name, :type => 'patient'} } unless(params[:q][:patient_id_in].nil?)
      selected_filters += Center.accessible_by(current_ability).where(:id => params[:q][:patient_center_id_in]).map {|center| {:id => 'center_'+center.id.to_s, :text => center.code + ' - ' + center.name, :type => 'center'} } unless(params[:q][:patient_center_id_in].nil?)
      selected_filters += Study.accessible_by(current_ability).where(:id => params[:q][:patient_center_study_id_in]).map {|study| {:id => 'study_'+study.id.to_s, :text => study.name, :type => 'study'} } unless(params[:q][:patient_center_study_id_in].nil?)

      return selected_filters
    end

    def index
      session[:current_images_filter] = nil if(params[:clear_filter] == 'true')

      if(params[:q] and params[:q][:visit_id_in] == [""])
        params[:q].delete(:visit_id_in)

        params[:q][:visit_id_in] = session[:current_images_filter] unless session[:current_images_filter].blank?
      elsif(params[:q].nil? or params[:q][:visit_id_in].nil?)
        params[:q] = {} if params[:q].nil?
        params[:q][:visit_id_in] = session[:current_images_filter] unless session[:current_images_filter].blank?
      elsif(params[:q] and
         params[:q][:visit_id_in].respond_to?(:length) and
         params[:q][:visit_id_in].length == 1 and
         params[:q][:visit_id_in][0].include?(',')
            )
        params[:q][:visit_id_in] = params[:q][:visit_id_in][0].split(',')
      end
      session[:current_images_filter] = params[:q][:visit_id_in] unless params[:q].nil? or params[:q][:visit_id_in].nil?

      if(params[:q] and params[:q][:visit_id_in].respond_to?(:each)) 
        visit_id_in = []

        params[:q][:visit_id_in].each do |id|         
          if(id =~ /^center_([0-9]*)/)
            params[:q][:patient_center_id_in] ||= []
            params[:q][:patient_center_id_in] << $1
          elsif(id =~ /^study_([0-9]*)/)
            params[:q][:patient_center_study_id_in] ||= []
            params[:q][:patient_center_study_id_in] << $1
          elsif(id =~ /^patient_([0-9]*)/)
            params[:q][:patient_id_in] ||= []
            params[:q][:patient_id_in] << $1
          elsif(id =~ /^visit_([0-9]*)/)
            visit_id_in << $1
          end
        end

        params[:q][:visit_id_in] = visit_id_in
      end
      pp params

      index!
    end
  end

  # this is a "fake" sidebar entry, which is only here to ensure that our data array for the advanced patient filter is rendered to the index page, even if it is empty
  # the resulting sidebar is hidden by the advanced filters javascript
  sidebar :advanced_filter_data, :only => :index do
    render :partial => 'admin/shared/advanced_filter_data', :locals => {:selected_filters => controller.generate_selected_filters, :filter_select2_id => 'visit_id'}
  end

  index do
    selectable_column
    benchmark('Study Column') do
      if(session[:selected_study_id].blank?)
        column :study do |image_series|
          link_to(image_series.study.name, admin_study_path(image_series.study)) unless image_series.study.nil?
        end
      end
    end                
    column :patient, :sortable => :patient_id
    column :visit, :sortable => :visit_id
    column :series_number
    column :name
    column :imaging_date
    column 'Import Date', :created_at
    column :images do |image_series|
      link_to('List', admin_images_path(:'q[image_series_id_eq]' => image_series.id))
    end
    benchmark('State column') do 
    column :state, :sortable => :state do |image_series|
      case image_series.state
      when :imported
        status_tag('Imported', :error)
      when :visit_assigned
        status_tag('Visit assigned', :warning)
      when :required_series_assigned
        assigned_required_series = image_series.assigned_required_series

        label = '<ul>'
        label += assigned_required_series.map {|ars| '<li>'+ars+'</li>'}.join('')
        label += '</ul>'

        ('<div class="status_tag required_series_assigned ok">'+label+'</div>').html_safe
      when :not_required
        status_tag('Not relevant for read')
      end
    end
    end
    
    column 'View (in)' do |image_series|
      result = ''

      result += link_to('Viewer', viewer_admin_image_series_path(image_series, :format => 'jnpl'), :class => 'member_link')
      result += link_to('Metadata', dicom_metadata_admin_image_series_path(image_series), :class => 'member_link', :target => '_blank')
      result += link_to('Domino', image_series.lotus_notes_url, :class => 'member_link') unless image_series.domino_unid.nil? or image_series.lotus_notes_url.nil?
      result += link_to('Assign Visit', assign_visit_form_admin_image_series_path(image_series, :return_url => request.fullpath), :class => 'member_link')
      result += link_to('Assign RS', assign_required_series_form_admin_image_series_path(image_series, :return_url => request.fullpath), :class => 'member_link') unless image_series.visit_id.nil?
      
      result.html_safe
    end
    
    default_actions
  end

  show do |image_series|
    attributes_table do
      row :patient
      row :visit
      row :series_number
      row :name
      domino_link_row(image_series)
      row :images do
        link_to(image_series.images.size, admin_images_path(:'q[image_series_id_eq]' => image_series.id))
      end
      row :image_storage_path
      row :imaging_date
      row 'Import Date' do
        pretty_format(image_series.created_at)
      end
      row :state do
        case image_series.state
        when :imported
          status_tag('Imported', :error)
        when :visit_assigned
          status_tag('Visit assigned', :warning)
        when :required_series_assigned
          status_tag('Required series assigned', :ok)
        when :not_required
          status_tag('Not relevant for read')
        end
      end
      row 'Required Series' do
        assigned_required_series = image_series.assigned_required_series
        if(assigned_required_series.empty?)
          "None assigned"
        else
          ul do
            assigned_required_series.each do |required_series_name|
              li { required_series_name }
            end
          end
        end
      end
      row 'Viewer' do
        link_to('View in Viewer', viewer_admin_image_series_path(image_series, :format => 'jnpl'))
      end
    end

    if(image_series.study and image_series.study.semantically_valid? and image_series.image_series_data and image_series.image_series_data.properties)
      properties_spec = image_series.study.current_configuration['image_series_properties']

      render :partial => 'admin/image_series/properties_table', :locals => { :spec => properties_spec, :values => image_series.image_series_data.properties}
    end
  end

  form do |f|
    resource.visit_id = params[:visit_id].to_i unless params[:visit_id].blank?

    patients = (session[:selected_study_id].nil? ? Patient.accessible_by(current_ability) : Study.find(session[:selected_study_id]).patients.accessible_by(current_ability))
    visits = (session[:selected_study_id].nil? ? Visit.accessible_by(current_ability) : Study.find(session[:selected_study_id]).visits.accessible_by(current_ability))

    f.inputs 'Details' do
      f.input :patient, :collection => (f.object.persisted? ? f.object.study.patients : patients), :include_blank => (not f.object.persisted?)
      f.input :visit, :collection => (f.object.persisted? ? f.object.study.visits : visits)
      f.input :series_number#, :hint => (f.object.persisted? ? '' : 'Leave blank to automatically assign the next available series number.'), :required => f.object.persisted?
      f.input :name
      f.input :imaging_date, :as => :datepicker
      f.input :force_update, :as => :hidden, :value => (params[:force_update] ? 'true' : 'false') if f.object.persisted?
      f.form_buffers.last # https://github.com/gregbell/active_admin/pull/965
    end

    f.buttons
  end

  # filters
  filter :visit, :collection => []
  filter :series_number
  filter :name
  filter :imaging_date
  filter :created_at, :label => 'Import Date'

  member_action :viewer, :method => :get do
    @image_series = ImageSeries.find(params[:id])
    authorize! :read, @image_series

    current_user.ensure_authentication_token!
    @wado_query_urls = [wado_query_image_series_url(@image_series, :format => :xml, :authentication_token => current_user.authentication_token)]

    render 'admin/shared/weasis_webstart.jnpl', :layout => false, :content_type => 'application/x-java-jnlp-file'
  end

  member_action :edit_properties, :method => :post do
    @image_series = ImageSeries.find(params[:id])

    if(@image_series.study.nil? or not @image_series.study.semantically_valid?)
      flash[:error] = 'Properties can only be edited once a valid study configuration was uploaded.'
      redirect_to({:action => :show})
    end

    @image_series.ensure_image_series_data_exists
    image_series_data = @image_series.image_series_data

    study_config = @image_series.study.current_configuration
    properties_spec = study_config['image_series_properties']
    image_series_data.properties = {} if image_series_data.properties.nil?

    properties_spec.each do |property_spec|
      new_value = params[:properties][property_spec['id']]

      case property_spec['type']
      when 'bool'
        new_value = (new_value == '1')
      end

      image_series_data.properties[property_spec['id']] = new_value
    end
    image_series_data.save
    @image_series.schedule_domino_sync

    redirect_to({:action => :show}, :notice => 'Properties successfully updated.')
  end
  member_action :edit_properties_form, :method => :get do
    @image_series = ImageSeries.find(params[:id])
    
    if(@image_series.study.nil? or not @image_series.study.semantically_valid?)
      flash[:error] = 'Properties can only be edited once a valid study configuration was uploaded.'
      redirect_to({:action => :show})
      return
    end

    study_config = @image_series.study.current_configuration
    @properties_spec = study_config['image_series_properties']

    @properties = (@image_series.image_series_data.nil? ? {} : @image_series.image_series_data.properties)

    @page_title = 'Edit Properties'
    render 'admin/image_series/edit_properties'
  end
  action_item :only => :show do
    link_to('Edit Properties', edit_properties_form_admin_image_series_path(resource))
  end

  member_action :mark_not_relevant, :method => :get do
    @image_series = ImageSeries.find(params[:id])

    if(@image_series.state != :visit_assigned or @image_series.visit.nil?)
      flash[:error] = 'Series can only be marked as not relevant for read once it has been assigned to a visit.'
      redirect_to :action => :show
      return
    end

    @image_series.state = :not_required
    @image_series.save

    redirect_to({:action => :show}, :notice => 'Series marked as not relevant for read.')
  end
  action_item :only => :show do
    link_to('Mark not relevant', mark_not_relevant_admin_image_series_path(resource)) unless (resource.state != :visit_assigned or resource.visit.nil?)
  end
  batch_action :mark_not_relevant, :confirm => 'This will mark all selected image series as not relevant. Are you sure?' do |selection|
    ImageSeries.find(selection).each do |i_s|
      next if (i_s.state != :visit_assigned or i_s.visit.nil?)

      i_s.state = :not_required
      i_s.save      
    end

    redirect_to(:back, :notice => 'Selected image series were marked as not relevant for read.')
  end

  member_action :dicom_metadata, :method => :get do
    @image_series = ImageSeries.find(params[:id])
    authorize! :read, @image_series

    sample_image = @image_series.sample_image
    if(sample_image.nil?)
      flash[:error] = 'This image series contains no images, so no DICOM Metadata is available.'
      redirect_to({:action => :show})
    end
    authorize! :read, sample_image

    @dicom_meta_header, @dicom_metadata = sample_image.dicom_metadata_as_arrays

    render 'admin/images/dicom_metadata'
  end
  action_item :only => :show do
    link_to('DICOM Metadata', dicom_metadata_admin_image_series_path(resource)) unless resource.images.empty?
  end

  collection_action :batch_assign_to_patient, :method => :post do
    if(params[:patient_id].nil?)
      flash[:error] = 'You have to select a patient to assign these image series to.'
      redirect_to :back
      return
    elsif(params[:image_series].nil?)
      flash[:error] = 'You have to specify at least one image series to assign to this patient.'
      redirect_to :back
      return
    end

    image_series_ids = params[:image_series].split(' ')
    image_series = ImageSeries.find(image_series_ids)

    patient = Patient.find(params[:patient_id])
    authorize! :manage, patient

    image_series.each do |i_s|
      authorize! :manage, i_s
      next unless i_s.visit_id.nil?
      
      i_s.patient = patient
      unless(i_s.series_number.blank? or i_s.patient.image_series.where(:series_number => i_s.series_number).empty?)
        i_s.series_number = nil
      end
      i_s.save
    end

    redirect_to params[:return_url], :notice => 'The image series were assigned to the patient.'
  end
  batch_action :assign_to_patient, :confirm => 'This will modify all selected image series. Are you sure?'  do |selection|
    failure = false
    study_id = nil
    
    ImageSeries.find(selection).each do |image_series|
      study_id = image_series.study.id if study_id.nil?

      if(image_series.study.id != study_id)
        flash[:error] = 'Not all selected image series belong to the same study. Batch assignment can only be used for series of the same study.'
        redirect_to :back
        failure = true
        break      
      elsif(image_series.visit_id != nil)
        flash[:error] = 'Not all selected image series are currently unassigned. Batch assignment can only be used for series which are not currently assigned to a visit.'
        redirect_to :back
        failure = true
        break
      end
    end
    next if failure

    @return_url = request.referer
    patients = Study.find(study_id).patients

    @page_title = 'Assign to Patient'
    render 'admin/image_series/assign_to_patient', :locals => {:selection => selection, :patients => patients}
  end

  collection_action :batch_assign_to_visit, :method => :post do
    if(params[:visit_id].blank?)
      flash[:error] = 'You have to select a visit to assign these image series to.'
      redirect_to :back
      return
    elsif(params[:image_series].blank?)
      flash[:error] = 'You have to specify at least one image series to assign to this visit.'
      redirect_to :back
      return
    end

    image_series_ids = params[:image_series].split(' ')
    image_series = ImageSeries.find(image_series_ids)

    if(params[:visit_id] == 'new')
      if(params[:visit][:visit_type].blank?)
        flash[:error] = 'When creating a new visit, a visit type must be selected.'
        redirect_to :back
        return
      end

      visit = Visit.create(:patient => image_series.first.patient, :visit_number => params[:visit][:visit_number], :visit_type => params[:visit][:visit_type], :description => params[:visit][:description])
    else
      visit = Visit.find(params[:visit_id])
    end
    authorize! :manage, visit

    image_series.each do |i_s|
      authorize! :manage, i_s
      next unless i_s.visit_id.nil?
      
      i_s.visit = visit
      i_s.save
    end

    redirect_to params[:return_url], :notice => 'The image series were assigned to the visit.'
  end
  batch_action :assign_to_visit, :confirm => 'This will modify all selected image series. Are you sure?'  do |selection|
    patient_id = nil
    visits = []
    visit_types = []
    failure = false
    
    ImageSeries.find(selection).each do |image_series|
      if patient_id.nil?
        patient_id = image_series.patient_id
        visits = image_series.patient.visits
        visit_types = (image_series.study ? image_series.study.visit_types : [])
      end
      
      if(image_series.patient_id != patient_id)
        flash[:error] = 'Not all selected image series belong to the same patient. Batch assignment can only be used for series from one patient which are not currently assigned to a visit.'
        redirect_to :back
        failure = true
        break
      elsif(image_series.visit_id != nil)
        flash[:error] = 'Not all selected image series are currently unassigned. Batch assignment can only be used for series from one patient which are not currently assigned to a visit.'
        redirect_to :back
        failure = true
        break
      end
    end
    next if failure

    @return_url = request.referer

    @page_title = 'Assign to Visit'
    render 'admin/image_series/assign_to_visit', :locals => {:selection => selection, :visits => visits, :visit_types => visit_types}
  end

  member_action :assign_visit, :method => :post do
    @image_series = ImageSeries.find(params[:id])
    authorize! :manage, @image_series

    if(params[:image_series][:visit_id] == 'new')
      if(params[:image_series][:visit][:visit_type].blank?)
        flash[:error] = 'When creating a new visit, a visit type must be selected.'
        redirect_to :back
        return
      end

      visit = Visit.create(:patient => @image_series.patient, :visit_number => params[:image_series][:visit][:visit_number], :visit_type => params[:image_series][:visit][:visit_type], :description => params[:image_series][:visit][:description])
    elsif(params[:image_series][:visit_id].blank?)
      visit = nil
    else
      visit = Visit.find(params[:image_series][:visit_id])
    end

    if(visit and visit.patient_id != @image_series.patient_id)
      flash[:error] = 'Visit doesn\'t belong to the image series curent patient. To change the patient, please \'Edit\' the image series.'
      redirect_to :back
      return
    end

    @image_series.visit = visit
    @image_series.save

    redirect_to params[:return_url], :notice => 'Image Series successfully assigned to visit.'
  end
  member_action :assign_visit_form, :method => :get do
    @image_series = ImageSeries.find(params[:id])
    authorize! :manage, @image_series

    if(@image_series.patient_id.nil?)
      flash[:error] = 'This image series is not assigned to a patient. Please assign a patient first!'
      redirect_to params[:return_url]
      return
    end
    @visit_types = (@image_series.patient and @image_series.patient.study ? @image_series.patient.study.visit_types : [])

    @return_url = params[:return_url]

    @page_title = 'Assign Visit'
  end

  member_action :assign_required_series, :method => :post do
    @image_series = ImageSeries.find(params[:id])
    authorize! :manage, @image_series

    @image_series.change_required_series_assignment(params[:image_series][:assigned_required_series].reject {|rs| rs.blank?})

    redirect_to params[:return_url], :notice => 'Image Series successfully assigned to required series.'
  end
  member_action :assign_required_series_form, :method => :get do
    @image_series = ImageSeries.find(params[:id])
    authorize! :manage, @image_series

    @required_series = @image_series.visit.required_series_names
    if(@required_series.blank?)
      flash[:error] = 'The associated visit has no required series. This could be due to an invalid study config, no assigned visit type or an empty visit type.'
      redirect_to params[:return_url]
      return
    end
    @assigned_required_series = @image_series.assigned_required_series
    @otherwise_assigned_required_series = []
    @image_series.visit.assigned_required_series_id_map.each do |required_series_name, assigned_image_series_id|
      @otherwise_assigned_required_series << required_series_name unless(assigned_image_series_id.blank? or assigned_image_series_id.to_i == @image_series.id)
    end

    @return_url = params[:return_url]

    @page_title = 'Assign Required Series'
  end

  controller do
    def build_image_series_tree_data(image_series)
      data = image_series.map do |i_s|
        children = i_s.images.map do |image|
          {'label' => view_context.link_to(image.id.to_s, admin_image_path(image), :target => '_blank').html_safe, 'id' => 'image_'+image.id.to_s, 'type' => 'image'}
        end
        
        {'label' => view_context.link_to(i_s.imaging_date.to_s + ' - ' +i_s.name, admin_image_series_path(i_s), :target => '_blank').html_safe, 'id' => 'image_series_'+i_s.id.to_s, 'children' => children, 'type' => 'image_series'}
      end

      return data
    end
  end
  collection_action :store_rearranged_images, :method => :post do
    begin
      raw_assignment = JSON.parse(params[:assignment])
    rescue JSON::JSONError => e
      Rails.logger.warn 'Failed to parse JSON coming from iamge series rearrange: '+e.message
      flash[:error] = 'Failed to save new assignment: '+e.message
      redirect_to :action => :index
      return
    end

    raw_assignment.each do |image_series|
      if(image_series['id'] =~ /^image_series_([0-9]*)$/)
        image_series_id = $1.to_i
      else
        next
      end

      next if image_series['children'].blank?
      image_series['children'].each do |image|
        if(image['id'] =~ /^image_([0-9]*)$/)
          image = Image.find($1)
          image.image_series_id = image_series_id
          image.save
        end        
      end
    end

    redirect_to({:action => :index}, :notice => 'The images were successfully reassigned.')
  end
  batch_action :rearrange, :label => 'Rearrange Images of ' do |selection|
    @tree_data = build_image_series_tree_data(ImageSeries.find(selection))

    patient_id = nil
    patient_mismatch = false
    image_series = ImageSeries.find(selection)
    image_series.each do |is|
      patient_id ||= is.patient_id

      if(patient_id != is.patient_id)
        patient_mismatch = true
        break
      end
    end
    if(patient_mismatch)
      flash[:error] = 'All image series must belong to the same patient.'
      redirect_to :back
      next
    end

    render 'admin/image_series/rearrange'
  end

  viewer_cartable(:image_series)
end
