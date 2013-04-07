ActiveAdmin.register Role do
  index do
    selectable_column
    column :user
    column :subject do |role|
      if role.subject.nil?
        'System'
      else
        auto_link(role.subject)
      end
    end
    column :role do |role|
      role.role_name
    end

    default_actions
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
    subjects = [["System", nil]] + Session.all.map{|s| ["Session: #{s.name}", "session_#{s.id}"]}
    roles = {}
    Role::ROLE_SYMS.each_with_index do |role_sym, index|
      roles[Role::ROLE_NAMES[index]] = role_sym
    end

    f.inputs 'Role details' do
      f.input :user, :required => true
      # HACK: we transform the malformed subject type in the Role model via a before_save filter and expand it into the proper subject_type and subject_id
      f.input :subject_type, :label => 'Subject', :collection => subjects
      f.input :role, :collection => roles, :as => :select, :include_blank => false
    end
    
    f.buttons
  end

  # filters
  filter :user
  filter :role, :as => :check_boxes, :collection => Role::ROLE_SYMS.each_with_index.map {|role, i| [role, i]}

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'role', :audit_trail_view_id => resource.id))
  end
end
