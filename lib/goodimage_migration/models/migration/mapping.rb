module GoodImageMigration
  module Migration
    class Mapping
      include DataMapper::Resource

      storage_names[:default] = 'mapping'

      property :id, Serial

      property :type, String, index: true
      property :source_id, Integer, index: true
      property :target_id, Integer, index: true
      property :migration_timestamp, DateTime

      def self.find_by_goodimage_resource(goodimage_resource)
        return nil if(goodimage_resource.nil? or goodimage_resource.id.blank?)

        type = self.resource_type(goodimage_resource)
        return nil if type.nil?

        Mapping.all(:type => type, :source_id => goodimage_resource.id)
      end

      def source
        return nil if(type.nil? or source_id.nil?)

        model_class = self.class.goodimage_resource_class_for_type(type)
        return nil if model_class.nil?

        model_class.get(source_id)
      end
      def target
        return nil if(type.nil? or target_id.nil?)

        model_class = self.class.erica_resource_class_for_type(type)
        return nil if model_class.nil?

        model_class.where(:id => target_id).first
      end

      def update_required?
        source = self.source
        return true if source.nil?
        return true unless source.respond_to?(:modification_timestamp)

        return source.modification_timestamp > migration_timestamp
      end

      protected

      def self.resource_type(resource)
        case resource
        when GoodImageMigration::GoodImage::Study, ::Study
          'study'
        when GoodImageMigration::GoodImage::CenterToStudy, ::Center
          'center'
        when GoodImageMigration::GoodImage::Patient, ::Patient
          'patient'
        when GoodImageMigration::GoodImage::PatientExamination, ::Visit
          'visit'
        when GoodImageMigration::GoodImage::SeriesImageSet, ::ImageSeries
          'image_series'
        when GoodImageMigration::GoodImage::Image, ::Image
          'image'
        else
          return nil
        end
      end
      def self.goodimage_resource_class_for_type(type)
        case type
        when 'study'
          GoodImageMigration::GoodImage::Study
        when 'center'
          GoodImageMigration::GoodImage::CenterToStudy
        when 'patient'
          GoodImageMigration::GoodImage::Patient
        when 'visit'
          GoodImageMigration::GoodImage::PatientExamination
        when 'image_series'
          GoodImageMigration::GoodImage::SeriesImageSet
        when 'image'
          GoodImageMigration::GoodImage::Image
        else
          return nil
        end
      end
      def self.erica_resource_class_for_type(type)
        case type
        when 'study'
          ::Study
        when 'center'
          ::Center
        when 'patient'
          ::Patient
        when 'visit'
          ::Visit
        when 'image_series'
          ::ImageSeries
        when 'image'
          ::Image
        else
          return nil
        end
      end
    end
  end
end
