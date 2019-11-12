module Migration
  # Adds `study_id` to all records in `versions` with `study_id = null`.
  class AddMissingVersionStudyId
    class << self
      def run
        fill_study_versions
        fill_center_versions
        fill_patient_versions
        fill_image_series_versions
        fill_image_versions
        fill_visit_versions
        fill_notification_versions
      end

      def fill_study_versions
        puts 'Finding Study versions study_ids'
        versions =
          Version
            .select('versions.id, versions.item_id AS study_id')
            .where('versions.item_type = ?', 'Study')
            .where('versions.study_id IS NULL')

        puts 'Saving Study versions study_ids'
        query =
          versions
            .map { |v| "UPDATE versions SET study_id = #{v.study_id} WHERE id = #{v.id};" }
            .join
        Version.connection.execute(query)
      end

      def fill_center_versions
        fill_versions(item_type: 'Center')
      end

      def fill_patient_versions
        fill_versions(item_type: 'Patient')
      end

      def fill_image_series_versions
        fill_versions(item_type: 'ImageSeries')
      end

      def fill_image_versions
        fill_versions(item_type: 'Image')
      end

      def fill_visit_versions
        fill_versions(item_type: 'Visit')
      end

      def fill_notification_versions
        join = <<JOIN
JOIN versions AS parent_versions
ON (
  parent_versions.id = (versions.object ->> 'version_id')::integer OR
  parent_versions.id = ((versions.object_changes ->> 'version_id')::jsonb ->> 1)::integer
)
JOIN
        fill_versions(item_type: 'Notification', join_query: join)
      end

      def fill_versions(item_type: nil, join_query: nil)
        puts "Finding #{item_type} versions study_ids"

        join_query ||= <<JOIN
JOIN versions AS parent_versions
ON (
  parent_versions.item_type = '#{parent_type(item_type)}' AND (
    parent_versions.item_id = (versions.object ->> '#{parent_key(item_type)}')::integer OR
    parent_versions.item_id = ((versions.object_changes ->> '#{parent_key(item_type)}')::jsonb ->> 1)::integer
  )
)
JOIN
        update_statements =
          Version
            .joins(join_query)
            .where('versions.item_type = ?', item_type)
            .where('versions.study_id IS NULL')
            .group('parent_versions.study_id')
            .pluck(Arel.sql('CONCAT(\'UPDATE versions SET study_id = \' || parent_versions.study_id || \'WHERE id IN (\' || string_agg(versions.id::varchar, \',\') || \')\') AS statement'))

        puts "Saving #{item_type} versions study_ids"
        update_statements.each do |statement|
          Version.connection.execute(statement)
        end
      end

      private

      def parent_type(item_type)
        case item_type
        when 'Center' then 'Study'
        when 'Patient' then 'Center'
        when 'ImageSeries' then 'Patient'
        when 'Image' then 'ImageSeries'
        when 'Visit' then 'Patient'
        end
      end

      def parent_key(item_type)
        case item_type
        when 'Center' then 'study_id'
        when 'Patient' then 'center_id'
        when 'ImageSeries' then 'patient_id'
        when 'Image' then 'image_series_id'
        when 'Visit' then 'patient_id'
        end
      end
    end
  end
end
