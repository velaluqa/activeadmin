ActiveAdmin.register View do

  actions :index, :show, :destroy

  index do
    selectable_column
    column :session
    column :position
    column :patient
    column :images
    column :view_type
    
    default_actions
  end

  form do |f|
    f.inputs 'Details' do
      f.input :session
      f.input :position
      f.input :patient      
      f.input :images
      f.input :view_type
    end

    f.buttons
  end  
end
