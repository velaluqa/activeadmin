ActiveAdmin.register Visit do

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :patient
    column :visit_number
    column :visit_type
    
    default_actions
  end

  show do |center|
    attributes_table do
      row :patient
      row :visit_number
      row :visit_type
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :patient
      f.input :visit_number
      f.input :visit_type
    end

    f.buttons
  end

  # filters
  filter :patient
  filter :visit_number
  filter :visit_type
end
