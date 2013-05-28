module GoodImageMigration
  module GoodImage
    class ImageDICOMKeyValue
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'image_dicom_key_value'

      property :id, Serial

      property :value, String

      belongs_to :image, child_key: 'image__id'
      belongs_to :parameter, child_key: 'parameter__id'
    end
  end
end
