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
    column :visit
    column :name
    
    default_actions
  end

  show do |center|
    attributes_table do
      row :visit
      row :name
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :visit
      f.input :name
    end

    f.buttons
  end

  # filters
  filter :visit
  filter :name
end
