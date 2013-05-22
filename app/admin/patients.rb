require 'aa_customizable_default_actions'
require 'aa_domino'

ActiveAdmin.register Patient do

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :center, :sortabel => :center_id
    column :subject_id
    
    customizable_default_actions do |resource|
      (resource.cases.empty? and resource.form_answers.empty?) ? [] : [:destroy]
    end
  end

  show do |patient|
    attributes_table do
      row :center
      row :subject_id
      domino_link_row(patient)
      row :image_storage_path
      row :patient_data_raw do
        CodeRay.scan(JSON::pretty_generate(patient.patient_data.data), :json).div(:css => :class).html_safe unless patient.patient_data.nil?
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :center, :collection => (f.object.persisted? ? f.object.study.centers : Center.all), :include_blank => (not f.object.persisted?)
      f.input :subject_id, :hint => (f.object.persisted? ? 'Do not change this unless you are absolutely sure you know what you do. This can lead to problems in project management, because the Subject ID is used to identify patients across documents.' : '')
    end

    f.buttons
  end

  # filters
  filter :center, :collection => Proc.new { Center.accessible_by(current_ability).order('id ASC') }
  filter :subject_id, :label => 'Subject ID'

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'patient', :audit_trail_view_id => resource.id))
  end

  viewer_cartable(:patient)
end
