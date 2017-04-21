module Migration
  # Adds `study_id` to all records in `versions` with `study_id = null`.
  class AddMissingVersionStudyId
    class << self
      def run
        Version.all.each do |version|
          next if version.study_id.present?
          version.update_attributes(study_id: find_study_id(version))
        end
      end

      def find_study_id(version)
        case version.item_type
        when 'Study'
          version.item_id
        when 'Center', 'Patient', 'ImageSeries', 'Image', 'Visit'
          find_study_id(recursive_version(version))
        when 'Notification'
          find_study_id(Version.find(version.complete_attributes['version_id']))
        end
      end

      private

      def recursive_version(version)
        Version
          .where(item_type: parent_type(version), item_id: foreign_key(version))
          .where('created_at < ?', version.created_at)
          .last
      end

      def parent_type(version)
        case version.item_type
        when 'Center' then 'Study'
        when 'Patient' then 'Center'
        when 'ImageSeries' then 'Patient'
        when 'Image' then 'ImageSeries'
        when 'Visit' then 'Patient'
        end
      end

      def foreign_key(version)
        foreign_key_column =
          case version.item_type
          when 'Center' then 'study_id'
          when 'Patient' then 'center_id'
          when 'ImageSeries' then 'patient_id'
          when 'Image' then 'image_series_id'
          when 'Visit' then 'patient_id'
          end
        version.complete_attributes[foreign_key_column]
      end
    end
  end
end
