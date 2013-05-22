require 'aa_customizable_default_actions'
require 'aa_domino'

ActiveAdmin.register Center do

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :study, :sortable => :study_id
    column :code
    column :name
    
    customizable_default_actions do |resource|
      resource.patients.empty? ? [] : [:destroy]
    end
  end

  show do |center|
    attributes_table do
      row :study
      row :code
      row :name
      domino_link_row(center)
      row :image_storage_path
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :study unless f.object.persisted?
      f.input :name
      f.input :code, :hint => (f.object.persisted? ? 'Do not change this unless you are absolutely sure you know what you do. This can lead to problems in project management, because the code is used to identify centers across documents.' : '')
    end

    f.buttons
  end

  # filters
  filter :study
  filter :name
  filter :code

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'center', :audit_trail_view_id => resource.id))
  end

  viewer_cartable(:center)
end
