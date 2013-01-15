ActiveAdmin.register Patient do
  index do
    selectable_column
    column :session
    column :subject_id
    column :images_folder
    
    default_actions
  end

  show do |patient|
    attributes_table do
      row :session
      row :subject_id
      row :images_folder
      row :patient_data do
        patient.patient_data.to_yaml
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :session
      f.input :subject_id
      f.input :images_folder
    end

    f.buttons
  end  
end
