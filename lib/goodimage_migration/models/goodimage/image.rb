module GoodImageMigration
  module GoodImage
    class Image
      include DataMapper::Resource

      storage_names[:goodimage] = 'image'

      property :id, Serial

      property :dicom_study_uid, String
      property :dicom_series_uid, String
      property :dicom_instance_uid, String

      property :window_width, Integer
      property :window_center, Integer

      property :file, String
      property :media_id, String

      property :idx, Integer

      property :medication, String
      property :organ, String

      property :use_as_series_reference, Boolean

      property :study_internal_id, String
      property :center_internal_id, String
      property :patient_internal_id, String

      property :nummer, Integer
      property :eintrag_id, Integer
      property :nummer_eintrag_id, String

      property :original_name, String

      belongs_to :series_image_set, child_key: 'series_image_set__id', required: false
      has n, :image_dicom_key_values, 'ImageDICOMKeyValue', child_key: 'image__id'
    end
  end
end
