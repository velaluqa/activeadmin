ActiveAdmin.register Version do
  actions :index, :show

  controller do
    def self.classify_event(version)
      return version.event if version.changeset.nil?

      case version.item_type
      when 'User'
        if(version.changeset.include?('sign_in_count') and
           version.changeset['sign_in_count'][1] == version.changeset['sign_in_count'][0]+1
           )
          return 'sign_in'
        end
      when 'Case'
        pp version.changeset
        if(version.changeset.include?('state'))
          case version.changeset['state']
          when [Case::state_sym_to_int(:unread), :in_progress], [Case::state_sym_to_int(:reopened), :reopened_in_progress]
            return 'case_reservation'
          when [Case::state_sym_to_int(:in_progress), :unread], [Case::state_sym_to_int(:reopened_in_progress), :reopened]
            return 'case_cancelation'
          when [Case::state_sym_to_int(:in_progress), :read], [Case::state_sym_to_int(:reopened_in_progress), :read]
            return 'case_completion'
          when [Case::state_sym_to_int(:read), :reopened]
            return 'case_reopened'
          end
        end
      end

      return version.event
    end
  end

  index do
    selectable_column
    column 'Timestamp', :created_at
    column :item_type
    column :item do |version|
      auto_link(version.item)
    end
    column :event do |version|
      case Admin::VersionsController.classify_event(version)
      when 'create'
        status_tag('Create', :ok)
      when 'update'
        status_tag('Update', :warning)
      when 'destroy'
        status_tag('Destroy', :error)
      when 'sign_in'
        status_tag('Sign-In', :ok)
      when 'case_reservation'
        status_tag('Case Reservation', :warning)
      when 'case_cancelation'
        status_tag('Case Cancelation', :error)
      when 'case_completion'
        status_tag('Case Completion', :ok)
      when 'case_reopened'
        status_tag('Case Reopened', :error)
      end
    end
    column :user do |version|
      if version.whodunnit.blank?
        'System'
      else
        auto_link(User.find_by_id(version.whodunnit.to_i))
      end
    end

    default_actions
  end

  show do |version|
    attributes_table do
      row :created_at
      row :item_type
      row :item do
        auto_link(version.item)
      end
      row :event do
        case Admin::VersionsController.classify_event(version)
        when 'create'
          status_tag('Create', :ok)
        when 'update'
          status_tag('Update', :warning)
        when 'destroy'
          status_tag('Destroy', :error)
        when 'sign_in'
          status_tag('Sign-In', :ok)
        when 'case_reservation'
          status_tag('Case Reservation', :warning)
        when 'case_cancelation'
          status_tag('Case Cancelation', :error)
        when 'case_completion'
          status_tag('Case Completion', :ok)
        when 'case_reopened'
          status_tag('Case Reopened', :error)
        end
      end
      row :user do
        if version.whodunnit.blank?
          'System'
        else
          auto_link(User.find_by_id(version.whodunnit.to_i))
        end
      end
      row :changes do
        unless(version.changeset.blank?)
          render 'admin/versions/changeset', :changeset => version.changeset, :item => version.item
        end
      end
    end
  end
end
