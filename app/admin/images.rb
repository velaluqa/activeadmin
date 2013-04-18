require 'rexml/document'

ActiveAdmin.register Image do

  actions :index, :show, :destroy

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

    file_path = Rails.application.config.image_storage_root + '/' + @image.image_storage_path
    dicom_xml = `#{Rails.application.config.dcm2xml} --quiet '#{file_path}'`
    dicom_metadata_doc = REXML::Document.new(dicom_xml)

    @dicom_meta_header = []
    unless(dicom_metadata_doc.root.elements['meta-header'].nil?)
      dicom_metadata_doc.root.elements['meta-header'].each_element('element') do |e|
        @dicom_meta_header << {:tag => e.attributes['tag'], :name => e.attributes['name'], :vr => e.attributes['vr'], :value => e.text} unless e.text.blank?
      end
    end

    @dicom_metadata = []
    unless(dicom_metadata_doc.root.elements['data-set'].nil?)
      dicom_metadata_doc.root.elements['data-set'].each_element('element') do |e|
        @dicom_metadata << {:tag => e.attributes['tag'], :name => e.attributes['name'], :vr => e.attributes['vr'], :value => e.text} unless e.text.blank?
      end    
    end
  end

  action_item :only => :show do
    link_to('DICOM Metadata', dicom_metadata_admin_image_path(resource)) if resource.file_is_present?
  end

  # filters
  filter :image_series
end
