require 'tempfile'

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
  has_paper_trail(
    class_name: 'Version',
    meta: {
      study_id: ->(image) { image.study.andand.id }
    }
  )

  attr_accessible(:image_series_id, :image_series)

  belongs_to :image_series

  validates_presence_of :image_series_id

  scope :by_study_ids, lambda { |*ids|
    joins(image_series: { patient: :center })
      .where(centers: { study_id: Array[ids].flatten })
  }

  scope :searchable, -> { join_study.select(<<SELECT.strip_heredoc) }
    centers.study_id AS study_id,
    studies.name AS study_name,
    image_series.series_number::text || '#' || images.id AS text,
    images.id AS result_id,
    'Image'::varchar AS result_type
SELECT

  scope :join_study, -> { joins(image_series: { patient: { center: :study } }) }

  include ImageStorageCallbacks
  include ScopablePermissions

  def self.with_permissions
    joins(image_series: { patient: { center: :study } }).joins(<<JOIN.strip_heredoc)
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
    image_series.andand.study
  end

  def image_storage_path
    "#{image_series.image_storage_path}/#{id}"
  end

  # TODO: Actually return an absolute path! This should be tested and
  # all usage should be verified!
  def absolute_image_storage_path
    Rails.application.config.image_storage_root + '/' + image_storage_path
  end

  def wado_uid
    Rails.application.config.wado_dicom_prefix + id.to_s
  end

  def file_is_present?
    File.readable?(Rails.application.config.image_storage_root + '/' + image_storage_path)
  end

  def write_anonymized_file(file)
    tmp = Tempfile.new('image_to_anonymize')
    begin
      tmp.binmode
      tmp.write(file)
      tmp.close

      tmp_dicom = DICOM::DObject.read(tmp.path)
      tmp_dicom.patients_name = "#{image_series.patient.center_id}#{image_series.patient.subject_id}"
      tmp_dicom.write(absolute_image_storage_path)
    ensure
      tmp.close
      tmp.unlink
    end
  end

  # TODO: Extract into separate PORO.
  def dicom_metadata
    dicom_metadata_doc = dicom_metadata_xml

    if dicom_metadata_doc.nil? || dicom_metadata_doc.root.nil?
      Rails.logger.warn 'Failed to retrieve metadata for image ' + id.to_s + ' at ' + image_storage_path
      return [{}, {}]
    end

    dicom_meta_header = {}
    unless dicom_metadata_doc.root.elements['meta-header'].nil?
      dicom_metadata_doc.root.elements['meta-header'].each_element('element') do |e|
        dicom_meta_header[e.attributes['tag']] = { tag: e.attributes['tag'], name: e.attributes['name'], vr: e.attributes['vr'], value: e.text } unless e.text.blank?
      end
    end

    dicom_metadata = {}
    unless dicom_metadata_doc.root.elements['data-set'].nil?
      dicom_metadata_doc.root.elements['data-set'].each_element('element') do |e|
        dicom_metadata[e.attributes['tag']] = { tag: e.attributes['tag'], name: e.attributes['name'], vr: e.attributes['vr'], value: e.text } unless e.text.blank?
      end
    end

    [dicom_meta_header, dicom_metadata]
  end

  def dicom_metadata_as_arrays
    dicom_metadata_doc = dicom_metadata_xml

    if dicom_metadata_doc.nil? || dicom_metadata_doc.root.nil?
      Rails.logger.warn 'Failed to retrieve metadata for image ' + id.to_s + ' at ' + image_storage_path
      return [[], []]
    end

    dicom_meta_header = []
    unless dicom_metadata_doc.root.elements['meta-header'].nil?
      dicom_metadata_doc.root.elements['meta-header'].each_element('element') do |e|
        dicom_meta_header << { tag: e.attributes['tag'], name: e.attributes['name'], vr: e.attributes['vr'], value: e.text } unless e.text.blank?
      end
    end

    dicom_metadata = []
    unless dicom_metadata_doc.root.elements['data-set'].nil?
      dicom_metadata_doc.root.elements['data-set'].each_element('element') do |e|
        dicom_metadata << { tag: e.attributes['tag'], name: e.attributes['name'], vr: e.attributes['vr'], value: e.text } unless e.text.blank?
      end
    end

    [dicom_meta_header, dicom_metadata]
  end

  def self.classify_audit_trail_event(c)
    :image_series_change if c.keys == ['image_series_id']
  end

  def self.audit_trail_event_title_and_severity(event_symbol)
    case event_symbol
    when :image_series_change then ['Image Series Change', :ok]
    end
  end

  protected

  def dicom_metadata_xml
    file_path = absolute_image_storage_path
    dicom_xml = `#{Rails.application.config.dcm2xml} --quiet '#{file_path}'`
    dicom_xml_clean = dicom_xml.encode('UTF-8', 'ISO-8859-1').scan(/[[:print:]]/).join
    begin
      dicom_metadata_doc = REXML::Document.new(dicom_xml_clean)
    rescue => e
      Rails.logger.warn 'Failed to parse DICOM metadata XML for image ' + id.to_s + ': ' + e.message
      return nil
    end

    dicom_metadata_doc
  end
end
