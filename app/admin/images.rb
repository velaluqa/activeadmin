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
      if session[:selected_study_id].nil?
        end_of_association_chain
      else
        end_of_association_chain.includes(image_series: { patient: :center }).where('centers.study_id' => session[:selected_study_id])
      end
    end

    before_action :authorize_erica_remote, only: :index, if: -> { ERICA.remote? }
    def authorize_erica_remote
      return if params[:format].blank?
      authorize! :download_status_files, Image
    end
  end

  index do
    selectable_column
    column :image_series
    column :id
    column 'Type', sortable: "mimetype" do |image|
      type = Marcel::Magic.new(image.mimetype).comment
      status_tag(type[2])
    end
    column 'Status' do |image|
      if image.file_is_present?
        status_tag('Present', class: 'ok')
      else
        status_tag('Missing', class: 'error')
      end
    end

    customizable_default_actions(current_ability)
  end

  show do |image|
    attributes_table do
      row :image_series
      row :id
      row :image_storage_path
      row 'Type' do
        type = Marcel::Magic.new(image.mimetype).comment
        status_tag(type.andand[2])
      end
      row 'SHA256 checksum' do
        if image.file_is_present?
          sha256sum =
            File.open(image.absolute_image_storage_path, 'rb') do |f|
              Digest::SHA256.hexdigest(f.read)
            end
          status_tag(image.sha256sum, image.sha256sum == sha256sum ? :ok : :error)
        else
          status_tag('Missing file', :error)
        end
      end
      row 'File' do
        if image.file_is_present?
          status_tag('Present', class: 'ok')
        else
          status_tag('Missing', class: 'error')
        end
      end
    end
  end

  member_action :dicom_metadata, method: :get do
    @image = Image.find(params[:id])
    authorize! :read, @image

    @dicom_meta_header, @dicom_metadata = @image.dicom_metadata_as_arrays
  end

  action_item :edit, only: :show do
    link_to('DICOM Metadata', dicom_metadata_admin_image_path(resource)) if resource.dicom?
  end

  action_item :audit_trail, only: :show, if: -> { can?(:read, Version) } do
    url = admin_versions_path(
      audit_trail_view_type: 'image',
      audit_trail_view_id: resource.id
    )
    link_to('Audit Trail', url)
  end
end
