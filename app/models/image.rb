#
#
# ## Schema Information
#
# Table name: `images`
#
# ### Columns
#
# Name                   | Type               | Attributes
# ---------------------- | ------------------ | ---------------------------
# **`created_at`**       | `datetime`         |
# **`id`**               | `integer`          | `not null, primary key`
# **`image_series_id`**  | `integer`          |
# **`updated_at`**       | `datetime`         |
#
# ### Indexes
#
# * `index_images_on_image_series_id`:
#     * **`image_series_id`**
#
class Image < ActiveRecord::Base
  has_paper_trail
  
  attr_accessible :image_series_id
  attr_accessible :image_series

  belongs_to :image_series

  validates_presence_of :image_series_id

  scope :by_study_ids, lambda { |*ids|
    joins(image_series: { patient: :center })
      .where(centers: { study_id: Array[ids].flatten })
  }

  include ImageStorageCallbacks
  include ScopablePermissions

  def self.with_permissions
    joins(<<JOIN)
INNER JOIN image_series ON image_series.id = images.image_series_id
INNER JOIN patients ON patients.id = image_series.patient_id
INNER JOIN centers ON centers.id = patients.center_id
INNER JOIN studies ON centers.study_id = studies.id
INNER JOIN user_roles ON
  (
       (user_roles.scope_object_type = 'Study'   AND user_roles.scope_object_id = studies.id)
    OR (user_roles.scope_object_type = 'Center'  AND user_roles.scope_object_id = centers.id)
    OR (user_roles.scope_object_type = 'Patient' AND user_roles.scope_object_id = patients.id)
    OR user_roles.scope_object_id IS NULL
  )
INNER JOIN roles ON user_roles.role_id = roles.id
INNER JOIN permissions ON roles.id = permissions.role_id
JOIN
  end

  def study
    if self.image_series.nil?
      nil
    else
      self.image_series.study
    end
  end

  def image_storage_path
    "#{image_series.image_storage_path}/#{id}"
  end
  def absolute_image_storage_path
    Rails.application.config.image_storage_root + '/' + self.image_storage_path
  end

  def wado_uid
    Rails.application.config.wado_dicom_prefix + self.id.to_s
  end

  def file_is_present?
    File.readable?(Rails.application.config.image_storage_root + '/' + image_storage_path)
  end

  ##
  # Writes the given contents to the image file specified by its
  # `absolute_image_storage_path`.
  #
  # @param [String] contents The content to write to the file (e.g.
  #                          return value of a previous `IO.read`)
  def write_file(contents)
    File.open(absolute_image_storage_path, 'wb') do |file|
      file.write(contents)
    end
  end

  def dicom_metadata
    dicom_metadata_doc = self.dicom_metadata_xml

    if(dicom_metadata_doc.nil? or dicom_metadata_doc.root.nil?)
      Rails.logger.warn 'Failed to retrieve metadata for image '+self.id.to_s+' at '+self.image_storage_path
      return [{},{}]
    end

    dicom_meta_header = {}
    unless(dicom_metadata_doc.root.elements['meta-header'].nil?)
      dicom_metadata_doc.root.elements['meta-header'].each_element('element') do |e|
        dicom_meta_header[e.attributes['tag']] = {:tag => e.attributes['tag'], :name => e.attributes['name'], :vr => e.attributes['vr'], :value => e.text} unless e.text.blank?
      end
    end

    dicom_metadata = {}
    unless(dicom_metadata_doc.root.elements['data-set'].nil?)
      dicom_metadata_doc.root.elements['data-set'].each_element('element') do |e|
        dicom_metadata[e.attributes['tag']] = {:tag => e.attributes['tag'], :name => e.attributes['name'], :vr => e.attributes['vr'], :value => e.text} unless e.text.blank?
      end    
    end

    return [dicom_meta_header, dicom_metadata]
    
  end

  def dicom_metadata_as_arrays
    dicom_metadata_doc = self.dicom_metadata_xml

    if(dicom_metadata_doc.nil? or dicom_metadata_doc.root.nil?)
      Rails.logger.warn 'Failed to retrieve metadata for image '+self.id.to_s+' at '+self.image_storage_path
      return [[],[]]
    end

    dicom_meta_header = []
    unless(dicom_metadata_doc.root.elements['meta-header'].nil?)
      dicom_metadata_doc.root.elements['meta-header'].each_element('element') do |e|
        dicom_meta_header << {:tag => e.attributes['tag'], :name => e.attributes['name'], :vr => e.attributes['vr'], :value => e.text} unless e.text.blank?
      end
    end

    dicom_metadata = []
    unless(dicom_metadata_doc.root.elements['data-set'].nil?)
      dicom_metadata_doc.root.elements['data-set'].each_element('element') do |e|
        dicom_metadata << {:tag => e.attributes['tag'], :name => e.attributes['name'], :vr => e.attributes['vr'], :value => e.text} unless e.text.blank?
      end    
    end

    return [dicom_meta_header, dicom_metadata]
  end

  def self.classify_audit_trail_event(c)
    if(c.keys == ['image_series_id'])
      :image_series_change
    end
  end
  def self.audit_trail_event_title_and_severity(event_symbol)
    return case event_symbol
           when :image_series_change then ['Image Series Change', :ok]
           end
  end

  protected
  
  def dicom_metadata_xml
    file_path = self.absolute_image_storage_path
    dicom_xml = `#{Rails.application.config.dcm2xml} --quiet '#{file_path}'`
    dicom_xml_clean = dicom_xml.encode('UTF-8', 'ISO-8859-1').scan(/[[:print:]]/).join
    begin
      dicom_metadata_doc = REXML::Document.new(dicom_xml_clean)
    rescue => e
      Rails.logger.warn 'Failed to parse DICOM metadata XML for image '+self.id.to_s+': '+e.message
      return nil
    end

    return dicom_metadata_doc
  end
end
