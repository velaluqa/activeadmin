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
end
