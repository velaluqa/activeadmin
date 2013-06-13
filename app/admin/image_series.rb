require 'aa_domino'

ActiveAdmin.register ImageSeries do

  scope :all, :default => true
  scope :not_assigned

  config.per_page = 100

  controller do
    load_and_authorize_resource :except => :index
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
      
      if(params[:image_series][:visit_id] != image_series.visit_id and params[:image_series][:force_update] != 'true')
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
            flash[:error] = 'The following required series\' in the new visit will have their assignment and tQC results overwritten by this change: '+already_assigned_required_series_names.join(", ")+'. If you want to continue, press "Update" again.'
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
      unless(new_visit.nil? or original_visit.visit_type != new_visit.visit_type)
        new_visit.change_required_series_assignment(new_visit_assignment_changes)

        unless(original_required_series.nil?)
          currently_assigned_required_series_names.each do |required_series_name|
            next if original_required_series[required_series_name].nil?
            new_visit.set_tqc_result(required_series_name,
                                     original_required_series[required_series_name]['tqc_results'], 
                                     original_required_series[required_series_name]['tqc_user_id'],
                                     original_required_series[required_series_name]['tqc_date'],
                                     original_required_series[required_series_name]['tqc_version'])
          end
        end
      end
      
      update!
      puts 'YEEEHAAAA!!!'
    end

    def generate_filter_options
      studies = if session[:selected_study_id].nil? then Study.accessible_by(current_ability) else Study.where(:id => session[:selected_study_id]).accessible_by(current_ability) end
      studies = studies.order('name asc')

      studies.map do |study|
        centers = study.centers.accessible_by(current_ability).order('code asc')
        
        centers_optgroups = centers.map do |center|
          patients = center.patients.accessible_by(current_ability).order('subject_id asc')

          patient_optgroups = patients.map do |patient|
            visits = patient.visits.accessible_by(current_ability).order('visit_number asc')

            visit_options = visits.map do |visit|
              {:id => "visit_#{visit.id.to_s}", :text => '#'+visit.visit_number.to_s}
            end

            {:id => "patient_#{patient.id.to_s}", :text => patient.subject_id, :children => visit_options}
          end

          {:id => "center_#{center.id.to_s}", :text => center.full_name, :children => patient_optgroups}
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

          center[:children].each do |patient|
            filter_options_map[patient[:id]] = patient[:text]
            
            patient[:children].each do |visit|
              filter_options_map[visit[:id]] = visit[:text]
            end
          end
        end
      end
      
      filter_options_map
    end
    def generate_selected_filters
      selected_filters = []

      selected_filters += params[:q][:visit_id_in].map {|s_id| "visit_#{s_id.to_s}"} unless(params[:q].nil? or params[:q][:visit_id_in].nil?)
      selected_filters += params[:q][:patient_id_in].map {|s_id| "patient_#{s_id.to_s}"} unless(params[:q].nil? or params[:q][:patient_id_in].nil?)
      selected_filters += params[:q][:patient_center_id_in].map {|s_id| "center_#{s_id.to_s}"} unless(params[:q].nil? or params[:q][:patient_center_id_in].nil?)
      selected_filters += params[:q][:patient_center_study_id_in].map {|s_id| "study_#{s_id.to_s}"} unless(params[:q].nil? or params[:q][:patient_center_study_id_in].nil?)

      return selected_filters
    end

    def index
      if(params[:q] and params[:q][:visit_id_in] == [""])
        params[:q].delete(:visit_id_in)
      elsif(params[:q] and
         params[:q][:visit_id_in].respond_to?(:length) and
         params[:q][:visit_id_in].length == 1 and
         params[:q][:visit_id_in][0].include?(','))
        params[:q][:visit_id_in] = params[:q][:visit_id_in][0].split(',')
      end

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
    filter_select2_data = controller.generate_filter_options
    filter_options_map = controller.generate_filter_options_map(filter_select2_data)
    render :partial => 'admin/shared/advanced_filter_data', :locals => {:filter_select2_data => filter_select2_data, :filter_options_map => filter_options_map, :selected_filters => controller.generate_selected_filters, :filter_select2_id => 'visit_id'}
  end

  index do
    selectable_column
    column :patient, :sortable => :patient_id
    column :visit, :sortable => :visit_id
    column :series_number
    column :name
    column :imaging_date
    column 'Import Date', :created_at
    column :images do |image_series|
      link_to(image_series.images.size, admin_images_path(:'q[image_series_id_eq]' => image_series.id))
    end
    column :state, :sortable => :state do |image_series|
      case image_series.state
      when :imported
        status_tag('Imported', :error)
      when :visit_assigned
        status_tag('Visit assigned', :warning)
      when :required_series_assigned
        status_tag('Required series\' assigned', :ok)
      when :not_required
        status_tag('Not relevant for read')
      end
    end
    
    column 'View (in)' do |image_series|
      result = ''

      result += link_to('Viewer', viewer_admin_image_series_path(image_series, :format => 'jnpl'), :class => 'member_link') unless image_series.images.empty?
      result += link_to('Metadata', dicom_metadata_admin_image_series_path(image_series), :class => 'member_link', :target => '_blank') unless image_series.images.empty?
      result += link_to('Domino', image_series.lotus_notes_url, :class => 'memeber_link') unless image_series.domino_unid.nil? or image_series.lotus_notes_url.nil?
      
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
          status_tag('Required series\' assigned', :ok)
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
      f.input :series_number, :hint => (f.object.persisted? ? '' : 'Leave blank to automatically assign the next available series number.'), :required => f.object.persisted?
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
    @image_series.update_image_series_properties_in_domino

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
  batch_action :mark_not_relevant do |selection|
    ImageSeries.find(selection).each do |i_s|
      next if (i_s.state != :visit_assigned or i_s.visit.nil?)

      i_s.state = :not_required
      i_s.save      
    end

    redirect_to(:back, :notice => 'Selected image series\' were marked as not relevant for read.')
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

  collection_action :batch_assign_to_visit, :method => :post do
    if(params[:visit_id].nil?)
      flash[:error] = 'You have to select a visit to assign these image series\' to.'
      redirect_to :back
      return
    elsif(params[:image_series].nil?)
      flash[:error] = 'You have to specify at least one image series to assign to this visit.'
      redirect_to :back
      return
    end

    image_series_ids = params[:image_series].split(' ')
    image_series = ImageSeries.find(image_series_ids)

    visit = Visit.find(params[:visit_id])
    authorize! :manage, visit

    image_series.each do |i_s|
      authorize! :manage, i_s
      next unless i_s.visit_id.nil?
      
      i_s.visit = visit
      i_s.save
    end

    redirect_to :action => :index, :notice => 'The image series\' were assigned to the visit.'
  end
  batch_action :assign_to_visit do |selection|
    patient_id = nil
    visits = []
    failure = false
    
    ImageSeries.find(selection).each do |image_series|
      if patient_id.nil?
        patient_id = image_series.patient_id
        visits = image_series.patient.visits
      end
      
      if(image_series.patient_id != patient_id)
        flash[:error] = 'Not all selected image series\' belong to the same patient. Batch assignment can only be used for series\' from one patient which are not currently assigned to a visit.'
        redirect_to :back
        failure = true
        break
      elsif(image_series.visit_id != nil)
        flash[:error] = 'Not all selected image series\' are currently unassigned. Batch assignment can only be used for series\' from one patient which are not currently assigned to a visit.'
        redirect_to :back
        failure = true
        break
      end
    end
    next if failure

    @page_title = 'Assign to Visit'
    render 'admin/image_series/assign_to_visit', :locals => {:selection => selection, :visits => visits}
  end

  viewer_cartable(:image_series)
end
