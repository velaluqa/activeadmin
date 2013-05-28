module GoodImageMigration
  module Migration
    class Mapping
      include DataMapper::Resource

      property :id, Serial

      property :type, String, index: true
      property :source_id, Integer, index: true
      property :target_id, Integer, index: true
      property :migration_timestamp, DateTime

      def source
        return nil if(type.nil? or source_id.nil?)

        model_class = case type
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

        model_class.get(source_id)
      end

      def update_required?
        source = self.source
        return true if source.nil?

        return source.modification_timestamp > migration_timestamp
      end
    end
  end
end
