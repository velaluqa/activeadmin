ActiveAdmin.register Role do
  menu if: proc { can? :read, Role }

  config.comments = false

  controller do
    load_and_authorize_resource :except => :index

    def max_csv_records
      1_000_000
    end

    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end

    def update
      # this verifies that the constraints on role creation/update on ERICA Remote admins are enforced
      updated_role = Role.new(params[:role])
      authorize! :update, updated_role

      update!
    end
  end

  index do
    selectable_column
    column :user, :sortable => :user_id
    column :subject, :sortable => :subject_id do |role|
      if role.subject.nil?
        'System'
      else
        auto_link(role.subject)
      end
    end
    column :role, :sortable => :role do |role|
      role.role_name
    end

    customizable_default_actions(current_ability)
  end

  show do |role|
    attributes_table do
      row :user
      row :subject do |role|
        if role.subject.nil?
          'System'
        else
          auto_link(role.subject)
        end
      end
      row :role do |role|
        role.role_name
      end
    end
  end

  form do |f|
    subjects = [["System", nil]] + Session.all.map{|s| ["Session: #{s.name}", "session_#{s.id}"]} + Study.all.map{|s| ["Study: #{s.name}", "study_#{s.id}"]}
    roles = {}
    Role::ROLE_SYMS.each_with_index do |role_sym, index|
      if(Rails.application.config.is_erica_remote)
        next unless role_sym.to_s.start_with?('remote_')
      else
        next if role_sym.to_s.start_with?('remote_')
      end

      roles[Role::ROLE_NAMES[index]] = role_sym
    end

    f.inputs 'Role details' do
      f.input :user, :required => true
      # HACK: we transform the malformed subject type in the Role model via a before_save filter and expand it into the proper subject_type and subject_id
      f.input :subject_type, :label => 'Subject', :collection => subjects
      f.input :role, :collection => roles, :as => :select, :include_blank => false, :hint => 'Please note that audit and read-only roles cannot be assigned system-wide and have to be assigned at a study or session level.'
    end
    
    f.buttons
  end

  # filters
  filter :user
  filter :role, :as => :check_boxes, :collection => Role::ROLE_SYMS.each_with_index.map {|role, i| [Role::role_sym_to_role_name(role), i]}

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'role', :audit_trail_view_id => resource.id)) if can? :read, Version
  end
end
