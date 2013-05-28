module GoodImageMigration
  module GoodImage
    class SeriesImageSet
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'series_image_set'

      property :id, Serial

      property :name, String
      property :comment, String

      property :original, Boolean
      property :se_qc_done, Boolean

      property :cd_internal_id, String

      property :creation_date, Time

      property :modification_timestamp, Time

      belongs_to :patient_examination_series, child_key: 'patient_examination_series__id', required: false
      has n, :images, child_key: 'series_image_set__id'
    end
  end
end
