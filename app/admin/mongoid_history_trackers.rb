ActiveAdmin.register MongoidHistoryTracker do
  before_filter { @skip_sidebar = true }

  menu false

  actions :index, :show

  controller do
    load_and_authorize_resource :except => :index

    def max_csv_records
      1_000_000
    end

    def scoped_collection
      return end_of_association_chain if(params[:audit_trail_view_type].nil? or params[:audit_trail_view_id].nil?)

      case params[:audit_trail_view_type]
      when 'case'
        end_of_association_chain.where(:'association_chain.name' => 'CaseData').in(:'association_chain.id' => CaseData.where(:case_id => params[:audit_trail_view_id].to_i).map {|cd| cd.id})
      when 'image_series'
        end_of_association_chain.where(:'association_chain.name' => 'ImageSeriesData').in(:'association_chain.id' => ImageSeriesData.where(:image_series_id => params[:audit_trail_view_id].to_i).map {|isd| isd.id})
      when 'visit'
        end_of_association_chain.or({:'association_chain.name' => 'VisitData', :'association_chain.id'.in => VisitData.where(:visit_id => params[:audit_trail_view_id].to_i).map {|vd| vd.id}},
                                    {:'association_chain.name' => 'ImageSeriesData', :'association_chain.id'.in => ImageSeriesData.where(:image_series_id.in => ImageSeries.where(:visit_id => params[:audit_trail_view_id].to_i).map {|is| is.id}).map {|isd| isd.id}})
      when 'patient'
        visit_data_ids = VisitData.in(:visit_id => Visit.where(:patient_id => params[:audit_trail_view_id].to_i).map {|v| v.id}).map {|vd| vd.id}
        image_series_data_ids = ImageSeriesData.in(:image_series_id => ImageSeries.where(:patient_id => params[:audit_trail_view_id].to_i).map {|is| is.id}).map {|isd| isd.id}

        end_of_association_chain.or({:'association_chain.name' => 'PatientData', :'association_chain.id'.in => PatientData.where(:patient_id => params[:audit_trail_view_id].to_i).map {|pd| pd.id}},
                                    {:'association_chain.name' => 'VisitData', :'association_chain.id'.in => visit_data_ids},
                                    {:'association_chain.name' => 'ImageSeriesData', :'association_chain.id'.in => image_series_data_ids})                                    
      when 'form_answer'
        end_of_association_chain.where('association_chain' => {'name' => 'FormAnswer', 'id' => Moped::BSON::ObjectId.from_string(params[:audit_trail_view_id])})
      when 'center'
        patient_ids = Patient.where(:center_id => params[:audit_trail_view_id].to_i).map {|p| p.id}

        patient_data_ids = PatientData.in(:patient_id => patient_ids).map {|pd| pd.id}
        visit_data_ids = VisitData.in(:visit_id => Visit.where(:patient_id => patient_ids).map {|v| v.id}).map {|vd| vd.id}
        image_series_data_ids = ImageSeriesData.in(:image_series_id => ImageSeries.where(:patient_id => patient_ids).map {|is| is.id}).map {|isd| isd.id}

        end_of_association_chain.or({:'association_chain.name' => 'PatientData', :'association_chain.id'.in => patient_data_ids},
                                    {:'association_chain.name' => 'VisitData', :'association_chain.id'.in => visit_data_ids},
                                    {:'association_chain.name' => 'ImageSeriesData', :'association_chain.id'.in => image_series_data_ids})                                    
      when 'session'
        case_data_ids = CaseData.in(:case_id => Case.where(:session_id => params[:audit_trail_view_id].to_i).map {|c| c.id}).map {|cd| cd.id}
        form_answer_ids = FormAnswer.where(:session_id => params[:audit_trail_view_id].to_i).map {|fa| fa.id}

        end_of_association_chain.or({:'association_chain.name' => 'CaseData', :'association_chain.id'.in => case_data_ids},
                                    {:'association_chain.name' => 'FormAnswer', :'association_chain.id'.in => form_answer_ids})
      when 'study'
        session_ids = Session.where(:study_id => params[:audit_trail_view_id].to_i).map {|s| s.id}

        case_data_ids = CaseData.in(:case_id => Case.where(:session_id => session_ids).map {|c| c.id}).map {|cd| cd.id}
        form_answer_ids = FormAnswer.where(:session_id.in => session_ids).map {|fa| fa.id}

        patient_ids = Patient.where(:center_id => Center.where(:study_id => params[:audit_trail_view_id].to_i).map {|c| c.id}).map {|p| p.id}

        patient_data_ids = PatientData.in(:patient_id => patient_ids).map {|pd| pd.id}
        visit_data_ids = VisitData.in(:visit_id => Visit.where(:patient_id => patient_ids).map {|v| v.id}).map {|vd| vd.id}
        image_series_data_ids = ImageSeriesData.in(:image_series_id => ImageSeries.where(:patient_id => patient_ids).map {|is| is.id}).map {|isd| isd.id}

        end_of_association_chain.or({:'association_chain.name' => 'CaseData', :'association_chain.id'.in => case_data_ids},
                                    {:'association_chain.name' => 'FormAnswer', :'association_chain.id'.in => form_answer_ids},
                                    {:'association_chain.name' => 'PatientData', :'association_chain.id'.in => patient_data_ids},
                                    {:'association_chain.name' => 'VisitData', :'association_chain.id'.in => visit_data_ids},
                                    {:'association_chain.name' => 'ImageSeriesData', :'association_chain.id'.in => image_series_data_ids})
      else
        end_of_association_chain
      end.accessible_by(current_ability)
    end

    def self.resource_name_for_tracker(tracker)
      unless(tracker.association_chain.blank? or tracker.association_chain[0]['name'].blank? or tracker.association_chain[0]['id'].blank?)
        tracker.association_chain[0]['name']
      else
        nil
      end
    end
    def self.classify_event(tracker)
      return tracker.action if tracker.tracked_changes.blank?
      c = tracker.tracked_changes

      event_symbol = tracker.action
      begin
        item_class = resource_name_for_tracker(tracker).constantize
        if item_class.respond_to?(:classify_mongoid_tracker_event)
          event_symbol = item_class::classify_mongoid_tracker_event(c) || event_symbol
        end
      rescue NameError
      end

      return event_symbol
    end
    def self.event_title_and_severity(item_type, event_symbol)
      if(['create', 'update', 'destroy'].include?(event_symbol))
         return case event_symbol
                when 'create' then ['Create', nil]
                when 'update' then ['Update', :warning]
                when 'destroy' then ['Destroy', :error]
                end
      end

      title = event_symbol.to_s.humanize
      severity = :warning
      begin
        item_class = item_type.constantize
        if item_class.respond_to?(:mongoid_tracker_event_title_and_severity)
          proper_title, proper_severity = item_class::mongoid_tracker_event_title_and_severity(event_symbol)
          title = proper_title || title
          severity = proper_severity || severity
        end
      rescue NameError => e
        pp e
      end

      return [title, severity]
    end

    def audit_trail_resource
      return nil if(params[:audit_trail_view_type].blank? or params[:audit_trail_view_id].blank?)

      result = case params[:audit_trail_view_type]
               when 'case' then Case.where(:id => params[:audit_trail_view_id].to_i).first
               when 'patient' then Patient.where(:id => params[:audit_trail_view_id].to_i).first
               when 'form' then Form.where(:id => params[:audit_trail_view_id].to_i).first
               when 'role' then Role.where(:id => params[:audit_trail_view_id].to_i).first
               when 'user' then User.where(:id => params[:audit_trail_view_id].to_i).first
               when 'session' then Session.where(:id => params[:audit_trail_view_id].to_i).first
               when 'study' then Study.where(:id => params[:audit_trail_view_id].to_i).first
               when 'form_answer' then FormAnswer.where(:id => params[:audit_trail_view_id]).first
               when 'center' then Center.where(:id => params[:audit_trail_view_id]).first
               when 'visit' then Visit.where(:id => params[:audit_trail_view_id]).first
               when 'image_series' then ImageSeries.where(:id => params[:audit_trail_view_id]).first
               when 'image' then Image.where(:id => params[:audit_trail_view_id]).first
               else nil
               end

      return result
    end
  end

  action_item :only => :index do
    resource = controller.audit_trail_resource
    status_tag(params[:audit_trail_view_type] + ': ' + (resource.respond_to?(:name) ? resource.name : '<'+resource.id+'>'), :error, :class => 'audit_trail_indicator') unless resource.nil?
  end

  index do
    selectable_column
    column 'Timestamp', :created_at, :sortable => :created_at
    column 'Resource' do |tracker|
      case Admin::MongoidHistoryTrackersController.resource_name_for_tracker(tracker)
      when 'FormAnswer'
        form_answer = FormAnswer.where(:id => tracker.association_chain[0]['id']).first
        if(form_answer.nil?)
          'Form Answer '+tracker.association_chain[0]['id'].to_s
        else
          ('Form Answer '+link_to(form_answer.id, admin_form_answer_path(form_answer))).html_safe
        end
      when 'CaseData'
        case_data = CaseData.where(:id => tracker.association_chain[0]['id']).first
        if(case_data.nil? or case_data.case.nil?)
          'Case Data '+tracker.association_chain[0]['id'].to_s
        else
          ('Case Data for '+link_to(case_data.case.name, admin_case_path(case_data.case))).html_safe
        end
      when 'PatientData'
        patient_data = PatientData.where(:id => tracker.association_chain[0]['id']).first
        if(patient_data.nil? or patient_data.patient.nil?)
          'Patient Data '+tracker.association_chain[0]['id'].to_s
        else
          ('Patient Data for '+link_to(patient_data.patient.name.to_s, admin_patient_path(patient_data.patient))).html_safe
        end
      when 'ImageSeriesData'
        image_series_data = ImageSeriesData.where(:id => tracker.association_chain[0]['id']).first
        if(image_series_data.nil? or image_series_data.image_series.nil?)
          'Image Series Data '+tracker.association_chain[0]['id'].to_s
        else
          ('Image Series Data for '+link_to(image_series_data.image_series.name.to_s, admin_image_series_path(image_series_data.image_series))).html_safe
        end
      when 'VisitData'
        visit_data = VisitData.where(:id => tracker.association_chain[0]['id']).first
        if(visit_data.nil? or visit_data.visit.nil?)
          'Visit Data '+tracker.association_chain[0]['id'].to_s
        else
          ('Visit Data for '+link_to(visit_data.visit.name.to_s, admin_visit_path(visit_data.visit))).html_safe
        end
      else
        nil
      end
    end
    column 'Event', :sortable => :action do |tracker|
      event = Admin::MongoidHistoryTrackersController.classify_event(tracker)
      event_title, event_severity = Admin::MongoidHistoryTrackersController.event_title_and_severity(Admin::MongoidHistoryTrackersController.resource_name_for_tracker(tracker), event)
      status_tag(event_title, event_severity)
    end
    column 'User', :sortable => :modifier_id do |tracker|
      if tracker.modifier.blank?
        'System'
      else
        auto_link(tracker.modifier)
      end
    end

    default_actions
  end

  show do |tracker|
    attributes_table do
      row :created_at
      row 'Resource' do
        case Admin::MongoidHistoryTrackersController.resource_name_for_tracker(tracker)
        when 'FormAnswer'
          form_answer = FormAnswer.where(:id => tracker.association_chain[0]['id']).first
          if(form_answer.nil?)
            'Form Answer '+tracker.association_chain[0]['id'].to_s
          else
            ('Form Answer '+link_to(form_answer.id, admin_form_answer_path(form_answer))).html_safe
          end
        when 'CaseData'
          case_data = CaseData.where(:id => tracker.association_chain[0]['id']).first
          if(case_data.nil? or case_data.case.nil?)
            'Case Data '+tracker.association_chain[0]['id'].to_s
          else
            ('Case Data for '+link_to(case_data.case.name, admin_case_path(case_data.case))).html_safe
          end
        when 'PatientData'
          patient_data = PatientData.where(:id => tracker.association_chain[0]['id']).first
          if(patient_data.nil? or patient_data.patient.nil?)
            'Patient Data '+tracker.association_chain[0]['id'].to_s
          else
            ('Patient Data for '+link_to(patient_data.patient.name.to_s, admin_patient_path(patient_data.patient))).html_safe
          end
        when 'ImageSeriesData'
          image_series_data = ImageSeriesData.where(:id => tracker.association_chain[0]['id']).first
          if(image_series_data.nil? or image_series_data.image_series.nil?)
            'Image Series Data '+tracker.association_chain[0]['id'].to_s
          else
            ('Image Series Data for '+link_to(image_series_data.image_series.name.to_s, admin_image_series_path(image_series_data.image_series))).html_safe
          end
        when 'VisitData'
          visit_data = VisitData.where(:id => tracker.association_chain[0]['id']).first
          if(visit_data.nil? or visit_data.visit.nil?)
            'Visit Data '+tracker.association_chain[0]['id'].to_s
          else
            ('Visit Data for '+link_to(visit_data.visit.name.to_s, admin_visit_path(visit_data.visit))).html_safe
          end
        else
          nil
        end
      end
      row 'Event' do
        pp tracker.tracked_changes
        event = Admin::MongoidHistoryTrackersController.classify_event(tracker)

        event_title, event_severity = Admin::MongoidHistoryTrackersController.event_title_and_severity(Admin::MongoidHistoryTrackersController.resource_name_for_tracker(tracker), event)
        status_tag(event_title, event_severity)
      end
      row 'User' do
        if tracker.modifier.blank?
          'System'
        else
          auto_link(tracker.modifier)
        end
      end
      row 'Changes' do
        render 'admin/mongoid_history_trackers/changeset', :changeset => tracker.tracked_changes, :item => tracker.resource
      end
    end
  end

  action_item :only => :index do
    link_to 'Versions', admin_versions_path({}.merge(params[:audit_trail_view_id].blank? ? {} : {:audit_trail_view_id => params[:audit_trail_view_id]}).merge(params[:audit_trail_view_type].blank? ? {} : {:audit_trail_view_type => params[:audit_trail_view_type]}))
  end
  action_item :only => :index do
    link_to 'Configuration Changes', git_commits_admin_versions_path({}.merge(params[:audit_trail_view_id].blank? ? {} : {:audit_trail_view_id => params[:audit_trail_view_id]}).merge(params[:audit_trail_view_type].blank? ? {} : {:audit_trail_view_type => params[:audit_trail_view_type]}))
  end
end
