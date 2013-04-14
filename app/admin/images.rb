ActiveAdmin.register Image do

  actions :index, :show, :destroy

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :image_series
    column :id
    
    default_actions
  end

  show do |center|
    attributes_table do
      row :image_series
      row :id
    end
  end

  # filters
  filter :image_series
end
