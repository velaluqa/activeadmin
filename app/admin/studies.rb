ActiveAdmin.register Study do

  index do
    selectable_column
    column :name, :sortable => :name do |study|
      link_to study.name, admin_study_path(study)
    end
    
    default_actions
  end

  show do |study|
    attributes_table do
      row :name
      row :image_storage_path
    end
  end
  
  form do |f|
    f.inputs 'Details' do
      f.input :name, :required => true
    end

    f.buttons
  end

  # filters
  filter :name

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'study', :audit_trail_view_id => resource.id))
  end
end
