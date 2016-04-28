require 'rexml/document'

ActiveAdmin.register Image do

  menu false
  if Rails.application.config.is_erica_remote
    actions :index, :show
  else
    actions :index, :show, :destroy
  end
  config.filters = false

  config.per_page = 100

  controller do
    def max_csv_records
      1_000_000
    end

    def scoped_collection
      if(session[:selected_study_id].nil?)
        end_of_association_chain
      else
        end_of_association_chain.includes(:image_series => {:patient => :center}).where('centers.study_id' => session[:selected_study_id])
      end
    end

    def index
      authorize! :download_status_files, Image if(Rails.application.config.is_erica_remote and not params[:format].blank?)

      index!
    end
  end

  index do
    selectable_column
    column :image_series
    column :id
    column 'File' do |image|
      if(image.file_is_present?)
        status_tag('Present', :ok)
      else
        status_tag('Missing', :error)
      end      
    end
    
    customizable_default_actions(current_ability)
  end

  show do |image|
    attributes_table do
      row :image_series
      row :id
      row :image_storage_path
      row 'File' do
        if(image.file_is_present?)
          status_tag('Present', :ok)
        else
          status_tag('Missing', :error)
        end
      end
    end
  end

  member_action :dicom_metadata, :method => :get do
    @image = Image.find(params[:id])
    authorize! :read, @image

    @dicom_meta_header, @dicom_metadata = @image.dicom_metadata_as_arrays
  end

  action_item :edit, :only => :show do
    link_to('DICOM Metadata', dicom_metadata_admin_image_path(resource)) if resource.file_is_present?
  end

  action_item :edit, :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'image', :audit_trail_view_id => resource.id)) if can? :read, Version
  end
end
