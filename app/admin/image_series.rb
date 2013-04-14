ActiveAdmin.register ImageSeries do

  scope :all, :default => true
  scope :not_assigned

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :patient
    column :visit
    column :name
    
    default_actions
  end

  show do |image_series|
    attributes_table do
      row :patient
      row :visit
      row :name
      row :image_storage_path
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :patient
      f.input :visit
      f.input :name
    end

    f.buttons
  end

  # filters
  filter :patient
  filter :visit
  filter :name
end
