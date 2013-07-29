ActiveAdmin.register MongoidHistoryTracker do
  before_filter { @skip_sidebar = true }

  menu :label => 'MHT', :priority => 99, :if => proc{ can?(:manage, MongoidHistoryTracker) }

  actions :index, :show

  controller do
    load_and_authorize_resource :except => :index
    # def scoped_collection
    #   end_of_association_chain.accessible_by(current_ability)
    # end
  end

  index do
    selectable_column
    column 'Timestamp', :created_at, :sortable => :created_at
    column 'Resource' do |tracker|
      unless(tracker.association_chain.blank? or tracker.association_chain[0]['name'].blank? or tracker.association_chain[0]['id'].blank?)
        case tracker.association_chain[0]['name']
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
        else
          nil
        end
      end
    end
    column 'Event', :sortable => :action do |tracker|
      case tracker.action
      when 'create'
        status_tag('Create', :ok)
      when 'update'
        status_tag('Update', :warning)
      when 'destroy'
        status_tag('Destroy', :error)
      end      
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
        unless(tracker.association_chain.blank? or tracker.association_chain[0]['name'].blank? or tracker.association_chain[0]['id'].blank?)
          case tracker.association_chain[0]['name']
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
          else
            nil
          end
        end
      end
      row 'Event' do
        case tracker.action
        when 'create'
          status_tag('Create', :ok)
        when 'update'
          status_tag('Update', :warning)
        when 'destroy'
          status_tag('Destroy', :error)
        end      
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
end
