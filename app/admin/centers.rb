require 'aa_customizable_default_actions'
require 'aa_domino'

ActiveAdmin.register Center do

  config.sort_order = 'code_asc'

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      if(session[:selected_study_id].nil?)
        end_of_association_chain.accessible_by(current_ability)
      else
        end_of_association_chain.accessible_by(current_ability).where(:study_id => session[:selected_study_id])
      end
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
      f.input :study, :collection => (session[:selected_study_id].nil? ? Study.accessible_by(current_ability) : Study.where(:id => session[:selected_study_id]).accessible_by(current_ability)) unless f.object.persisted?
      f.input :name
      f.input :code, :hint => (f.object.persisted? ? 'Do not change this unless you are absolutely sure you know what you do. This can lead to problems in project management, because the code is used to identify centers across documents.' : '')
    end

    f.buttons
  end

  # filters
  filter :study, :collection => proc { session[:selected_study_id].nil? ? Study.accessible_by(current_ability) : Study.where(:id => session[:selected_study_id]).accessible_by(current_ability) }
  filter :name
  filter :code

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'center', :audit_trail_view_id => resource.id))
  end

  viewer_cartable(:center)
end
