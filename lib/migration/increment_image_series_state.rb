module Migration
  # With the introduction of the `importing` state for image series,
  # we have to adjust existing data sets to
  class IncrementImageSeriesState
    class << self
      def run
        if fix_version_object_changes?
          puts 'There are versions with wrong state changes in `object_changes`'
          puts 'Run `rake erica:migration:fix_version_object_changes_for_state_columns` first.'
          return
        end

        ImageSeries.skip_update_state_callback = true

        puts "Updating image series state values: #{ImageSeries.count}"
        time = Benchmark.realtime do
          ActiveRecord::Base.connection.execute("UPDATE image_series SET state = state + 1;")
        end
        puts "Time elapsed #{time*1000} milliseconds"

        puts "Updating image series version `object` state values: #{Version.where('item_type = \'ImageSeries\' AND object::jsonb ? \'state\'').count}"
        time = Benchmark.realtime do
          ActiveRecord::Base.connection.execute(<<SQL)
UPDATE versions
SET object = object::jsonb || CONCAT('{"state":', (object->>'state')::int + 1, '}')::jsonb
WHERE item_type = 'ImageSeries' AND object::jsonb ? 'state'
SQL
        end
        puts "Time elapsed #{time*1000} milliseconds"

        puts "Updating image series version `object_changes` for creates: #{Version.where("item_type = 'ImageSeries' AND event = 'create'").count}"
        time = Benchmark.realtime do
          ActiveRecord::Base.connection.execute(<<SQL)
UPDATE versions
SET object_changes = object_changes || CONCAT('{"state":[0', ',', COALESCE(object_changes#>>'{state,1}', '0')::int + 1, ']}')::jsonb
WHERE item_type = 'ImageSeries' AND event = 'create'
SQL
        end
        puts "Time elapsed #{time*1000} milliseconds"

        puts "Updating image series version `object_changes` for updates: #{Version.where("item_type = 'ImageSeries' AND event != 'create' AND object_changes ? 'state'").count}"
        time = Benchmark.realtime do
          ActiveRecord::Base.connection.execute(<<SQL)
UPDATE versions
SET object_changes = object_changes || CONCAT('{"state":[', COALESCE(object_changes#>>'{state,0}', '0')::int + 1, ',', COALESCE(object_changes#>>'{state,1}', '0')::int + 1, ']}')::jsonb
WHERE item_type = 'ImageSeries' AND event != 'create' AND object_changes ? 'state'
SQL
        end
        puts "Time elapsed #{time*1000} milliseconds"

        ImageSeries.skip_update_state_callback = false
      end

      def image_series_with_latest_state?
        ImageSeries.where(state: ImageSeries::STATE_SYMS.length - 1).exist?
      end

      def fix_version_object_changes?
        Version
          .where(item_type: 'ImageSeries')
          .where('object_changes #>> \'{state,1}\' IN (?)', ImageSeries::STATE_SYMS)
          .exists?
      end
    end
  end
end
