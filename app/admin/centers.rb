require 'aa_customizable_default_actions'

ActiveAdmin.register Center do

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :study
    column :name
    
    customizable_default_actions do |resource|
      resource.patients.empty? ? [] : [:destroy]
    end
  end

  show do |center|
    attributes_table do
      row :study
      row :name
      row :image_storage_path
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :study
      f.input :name
    end

    f.buttons
  end

  # filters
  filter :study
  filter :name

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'center', :audit_trail_view_id => resource.id))
  end
end
