module Migration
  class MigrateRequiredSeriesPresets
    class << self
      def run
        PaperTrail.enabled = false
        visit_versions_with_type.each do |version|
          next remove_required_series(version) if version.event == 'destroy'
          was, becomes = version.complete_changes['visit_type']
          config = study_configuration(version.study_id, version.created_at.to_time)
          if was.blank? && becomes.present?
            old = []
            new = config.andand['visit_types'].andand[becomes].andand['required_series'].try(:keys) || []
          elsif was.present? && becomes.present?
            old = config.andand['visit_types'].andand[was].andand['required_series'].try(:keys) || []
            new = config.andand['visit_types'].andand[becomes].andand['required_series'].try(:keys) || []
          elsif was.present? && becomes.blank?
            old = config.andand['visit_types'].andand[was].andand['required_series'].try(:keys) || []
            new = []
          end
          create_required_series_presets(version, new)
          remove_required_series_presets(version, (old - new))
        end
        PaperTrail.enabled = true
      end

      def create_required_series_presets(version, required_series_names)
        required_series_names.each do |name|
          next if RequiredSeries.where(visit_id: version.item_id, name: name).exists?
          required_series =
            RequiredSeries.create!(
              visit_id: version.item_id,
              name: name,
              created_at: version.created_at,
              updated_at: version.created_at
            )
          Version.create!(
            item_type: 'RequiredSeries',
            item_id: required_series.id,
            event: 'create',
            object: nil,
            object_changes: {
              visit_id: [nil, version.item_id],
              name: [nil, name],
              created_at: [nil, version.created_at.iso8601],
              updated_at: [nil, version.created_at.iso8601]
            },
            created_at: version.created_at,
            updated_at: version.created_at,
            study_id: version.study_id
          )
        end
      end

      def remove_required_series_presets(version, required_series_names)
        required_series_names.each do |name|
          required_series = RequiredSeries.where(visit_id: version.item_id, name: name).first
          next if required_series.blank?
          destroy_required_series(version, required_series)
        end
      end

      def remove_required_series(version)
        RequiredSeries.where(visit_id: version.item_id).each do |required_series|
          destroy_required_series(version, required_series)
        end
      end

      def destroy_required_series(version, required_series)
        Version.create!(
          item_type: 'RequiredSeries',
          item_id: required_series.id,
          event: 'destroy',
          object: JSON.parse(required_series.to_json),
          object_changes: nil,
          created_at: version.created_at,
          updated_at: version.created_at,
          study_id: version.study_id
        )
        required_series.destroy!
      end

      def visit_versions_with_type
        Version
          .where(item_type: 'Visit')
          .where(<<CLAUSE.strip_heredoc)
            (event = 'destroy' AND object ->> 'visit_type' IS NOT NULL)
         OR ((object_changes ->> 'visit_type')::jsonb -> 1 IS NOT NULL)
CLAUSE
          .order(created_at: :asc)
      end

      def locked_study_version_at(study_id, timestamp)
        version =
          Version
            .where(item_type: 'Study', item_id: study_id)
            .where('created_at < ?', timestamp)
            .last
        return version.complete_attributes['locked_version'] if version
        study = Study.where(id: study_id).first
        study = study.paper_trail.version_at(timestamp) || study
        study.andand.locked_version
      end

      def study_configuration(study_id, timestamp)
        repo = GitConfigRepository.new
        former_locked_version = locked_study_version_at(study_id, timestamp)
        former_current_version = repo.version_at(timestamp)
        version = former_locked_version || former_current_version
        return nil if version.nil?
        repo.yaml_at_version(study_config_path(study_id), version)
      end

      def study_config_path(id)
        Rails.application.config.study_configs_subdirectory + "/#{id}.yml"
      end
    end
  end
end
