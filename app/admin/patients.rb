ActiveAdmin.register Patient do

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
    
    default_actions
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
end
