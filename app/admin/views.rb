ActiveAdmin.register View do
  index do
    selectable_column
    column :session
    column :position
    column :patient
    column :images
    column :form
    
    default_actions
  end

  form do |f|
    f.inputs 'Details' do
      f.input :session
      f.input :position
      f.input :patient      
      f.input :images
      f.input :form
    end

    f.buttons
  end  
end
