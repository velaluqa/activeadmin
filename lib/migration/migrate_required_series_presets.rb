module Migration
  class MigrateRequiredSeriesPresets
    class << self
      def run
        PaperTrail.enabled = false
        ActiveRecord::Base.record_timestamps = false

        # create_presets_from_visit_type_change
        create_presets_from_study_configuration_change
      ensure
        PaperTrail.enabled = true
        ActiveRecord::Base.record_timestamps = true
      end

      def create_presets_from_visit_type_change
        progress = ProgressBar.create(
          title: 'Required Series Presets',
          total: visit_versions_with_type.count,
          format: '%t |%B| %a / %E (%c / %C ~ %p%%)'
        )
        visit_versions_with_type.find_each do |version|
          binding.pry
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

          progress.increment
        end
      end

      def create_presets_from_study_configuration_change
        puts 'About to migrate preset changes from study configuration changes'
        study_ids = Version.pluck('DISTINCT(study_id)').compact

        study_ids.each do |study_id|
          previous_config = {}
          repo = GitConfigRepository.new
          config_path = Rails.application.config.study_configs_subdirectory + "/#{study_id}.yml"
          commits = repo.commits_for_file(config_path)
          puts "Commits for study with id #{study_id}"
          commits.each do |commit|
            commit_config = repo.yaml_at_version(config_path, commit.oid)
            migrate_config_change(study_id, commit, previous_config, commit_config)
            previous_config = commit_config
          end
        end
      end

      def migrate_config_change(study_id, commit, previous_config, commit_config)
        old_visit_types = previous_config.andand['visit_types'].try(:keys) || []
        new_visit_types = commit_config.andand['visit_types'].try(:keys) || []

        # Visit types added to the configuration. Look for visits that
        # need to be updated with the new required series.
        (new_visit_types - old_visit_types).each do |visit_type|
          add_visit_type_required_series(study_id, commit, visit_type, commit_config)
        end
        # Visit types removed from the configuration. Remove any
        # existing required series.
        (old_visit_types - new_visit_types).each do |visit_type|
          remove_visit_type_required_series(study_id, commit, visit_type, previous_config)
        end
        # Visit types kept but maybe updated. Look for added or
        # removed required series and migrate changes.
        (old_visit_types & new_visit_types).each do |visit_type|
          handle_visit_type_required_series_update(study_id, commit, visit_type, previous_config, commit_config)
        end
      end

      def add_visit_type_required_series(study_id, commit, visit_type, commit_config)
        new_rs = commit_config.andand['visit_types'].andand[visit_type].andand['required_series'].try(:keys) || []

      end

      def remove_visit_type_required_series(study_id, commit, visit_type, previous_config)
        old_rs = previous_config.andand['visit_types'].andand[visit_type].andand['required_series'].try(:keys) || []

      end

      def handle_visit_type_required_series_update(study_id, commit, visit_type, previous_config, commit_config)
        old_rs = previous_config.andand['visit_types'].andand[visit_type].andand['required_series'].try(:keys) || []
        new_rs = commit_config.andand['visit_types'].andand[visit_type].andand['required_series'].try(:keys) || []


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
              created_at: [nil, version.created_at.as_json],
              updated_at: [nil, version.created_at.as_json]
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
          .where(item_type: 'Visit', item_id: 9714)
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
            .order(id: :desc)
            .first
        return version.complete_attributes['locked_version'] if version
        study = Study.where(id: study_id).first
        binding.pry if study.nil?
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
