module Migration
  class MigrateRequiredSeriesChanges
    class << self
      def run
        PaperTrail.enabled = false
        ActiveRecord::Base.record_timestamps = false

        RequiredSeries.skip_callback(:save, :after, :update_image_series_state)

        progress = ProgressBar.create(
          title: 'Required Series Changes',
          total: versions.count,
          format: '%t |%B| %a / %E (%c / %C ~ %p%%)'
        )
        versions.find_each do |version|
          required_series_changes(version).each do |mapping|
            create_required_series_version(version, **mapping)
          end
          progress.increment
        end
        RequiredSeries.set_callback(:save, :after, :update_image_series_state)
      ensure
        PaperTrail.enabled = true
        ActiveRecord::Base.record_timestamps = true
      end

      def create_required_series_version(visit_version, visit_id:, name:, changes:)
        latest_version = find_latest_required_series_version(visit_id, name)
        binding.pry if latest_version.nil?
        changes = non_obsolete_changes(latest_version, visit_version, changes)
        return if Version.where(created_at: visit_version.created_at, item_id: latest_version.item_id, item_type: 'RequiredSeries').exists?
        return if changes.blank?
        Version.create(
          item_type: 'RequiredSeries',
          item_id: latest_version.item_id,
          event: 'update',
          object: latest_version.complete_attributes,
          object_changes: changes,
          created_at: visit_version.created_at,
          study_id: visit_version.study_id
        )
        required_series = RequiredSeries.where(id: latest_version.item_id).first
        return if required_series.nil?
        attributes = changes.transform_values { |_, new| new }
        required_series.update_attributes(attributes)
        required_series.save!
      end

      def find_latest_required_series_version(visit_id, name)
        Version
          .where(item_type: 'RequiredSeries')
          .where(<<CLAUSE.strip_heredoc, visit_id: visit_id, name: name)
            (
              ((object ->> 'name') LIKE :name) OR
              ((object_changes #>> '{name,1}') LIKE :name)
            ) AND (
              ((object ->> 'visit_id')::int = :visit_id) OR
              ((object_changes #>> '{visit_id,1}')::int = :visit_id)
            )
CLAUSE
          .order(:created_at, :id)
          .last
      end

      def versions
        Version
          .where(item_type: 'Visit')
          .where(<<CLAUSE.strip_heredoc)
            (("object_changes" ->> 'required_series')::jsonb -> 0 IS NOT NULL)
         OR (("object_changes" ->> 'required_series')::jsonb -> 1 IS NOT NULL)
         OR ("object" ->> 'required_series' IS NOT NULL)
CLAUSE
          .order(created_at: :asc)
      end

      def non_obsolete_changes(latest_version, visit_version, changes)
        complete_attributes = latest_version.complete_attributes
        changes = changes.delete_if do |col, (_, became)|
          complete_attributes.andand[col] == became
        end
        if changes.present?
          changes['updated_at'] = [
            complete_attributes['updated_at'] || complete_attributes['created_at'],
            visit_version.created_at
          ]
        end
        changes
      end

      def required_series_changes(visit_version)
        was, becomes = visit_version.complete_changes['required_series']
        ((was.andand.keys || []) + (becomes.andand.keys || [])).uniq.map do |required_series_name|
          {
            visit_id: visit_version.item_id,
            name: required_series_name,
            changes: RequiredSeries.columns.map do |column|
              was_value = was.andand[required_series_name].andand[column.name]
              becomes_value = becomes.andand[required_series_name].andand[column.name]
              next if was_value == becomes_value
              if column.name == 'tqc_state'
                enum = RequiredSeries.defined_enums[column.name].invert
                [column.name, [enum[was_value], enum[becomes_value]]]
              elsif column.name == 'image_series_id'
                [column.name, [was_value.andand.to_i, becomes_value.andand.to_i]]
              elsif column.name == 'tqc_date'
                [column.name, [
                   was_value.present? ? DateTime.parse(was_value) : nil,
                   becomes_value.present? ? DateTime.parse(becomes_value) : nil
                 ]]
              else
                [column.name, [was_value, becomes_value]]
              end
            end.compact.to_h
          }
        end
      end
    end
  end
end
