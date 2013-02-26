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

    f.inputs 'Role details' do
      f.input :user, :required => true
      # HACK: we transform the malformed subject type in the Role model via a before_save filter and expand it into the proper subject_type and subject_id
      f.input :subject_type, :label => 'Subject', :collection => subjects
      f.input :role, :collection => {"Manager" => :manage}, :as => :select, :include_blank => false
    end
    
    f.buttons
  end
end
