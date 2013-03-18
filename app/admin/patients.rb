require 'aa_customizable_default_actions'

ActiveAdmin.register Patient do

  actions :index, :show, :destroy
  config.clear_action_items! # get rid of the default action items, since we have to handle 'delete' on a case-by-case basis

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :session
    column :subject_id
    
    customizable_default_actions do |resource|
      resource.cases.empty? ? [] : [:destroy]
    end
  end

  show do |patient|
    attributes_table do
      row :session
      row :subject_id
      row :patient_data_raw do
        CodeRay.scan(JSON::pretty_generate(patient.patient_data.data), :json).div(:css => :class).html_safe unless patient.patient_data.nil?
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :session
      f.input :subject_id
    end

    f.buttons
  end

  # filters
  filter :session
  filter :subject_id, :label => 'Subject ID'

  action_item :only => :show do
    # copied from activeadmin/lib/active_admin/resource/action_items.rb#add_default_action_items
    if controller.action_methods.include?('destroy') and resource.cases.empty?
      link_to(I18n.t('active_admin.delete_model', :model => active_admin_config.resource_label),
              resource_path(resource),
              :method => :delete, :data => {:confirm => I18n.t('active_admin.delete_confirmation')})
    end
  end 

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'patient', :audit_trail_view_id => resource.id))
  end
end
