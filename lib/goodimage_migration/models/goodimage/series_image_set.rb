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

      def series_number
        name_parts = self.name.split('_')
        
        if(name_parts.size == 4)
          return name_parts[3].to_i
        else
          return nil
        end
      end
      def proper_series_name
        name_parts = self.name.split('_', 4)

        if(name_parts.size >= 4)
          return name_parts[3]
        else
          return nil
        end
      end

      def imaging_date(parameter_ids)
        return nil if self.images.empty?

        first_image = self.images.first

        imaging_date_raw = nil
        parameter_ids.each do |parameter_id|
          values = first_image.image_dicom_key_values.all(:parameter__id => parameter_id)

          unless(values.empty?)
            imaging_date_raw = values[0].value

            break unless imaging_date_raw.nil?
          end
        end

        return nil if imaging_date_raw.nil?
        return Date.strptime(imaging_date_raw, '%Y%m%d')
      end

      def equivalent_series
        return nil if self.images.empty?

        first_image = self.images.first
        dicom_instance_uid = first_image.dicom_instance_uid
        return nil if dicom_instance_uid.nil?

        equivalent_images = GoodImageMigration::GoodImage::Image.all(:id.not => first_image.id, :dicom_instance_uid => dicom_instance_uid)

        equivalent_series = equivalent_images.map {|image| image.series_image_set}.uniq

        return equivalent_series
      end

      def migration_children
        return self.images
      end
    end
  end
end
