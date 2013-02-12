ActiveAdmin.register Study do

  index do
    selectable_column
    column :name do |study|
      link_to study.name, admin_study_path(study)
    end
    
    default_actions
  end

  show do |study|
    attributes_table do
      row :name
    end
  end
  
  form do |f|
    f.inputs 'Details' do
      f.input :name, :required => true
    end

    f.buttons
  end
end
