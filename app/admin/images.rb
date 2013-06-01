require 'rexml/document'

ActiveAdmin.register Image do

  actions :index, :show, :destroy

  config.per_page = 100

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
    column 'File' do |image|
      if(image.file_is_present?)
        status_tag('Present', :ok)
      else
        status_tag('Missing', :error)
      end      
    end
    
    default_actions
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

  action_item :only => :show do
    link_to('DICOM Metadata', dicom_metadata_admin_image_path(resource)) if resource.file_is_present?
  end

  # filters
  filter :image_series
end
