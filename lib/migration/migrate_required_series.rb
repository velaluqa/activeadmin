module Migration
  class MigrateRequiredSeries
    class << self
      def run
        PaperTrail.enabled = false
        ActiveRecord::Base.record_timestamps = false
        RequiredSeries.skip_callback(:commit, :after, :schedule_domino_sync)
        RequiredSeries.skip_callback(:save, :after, :update_image_series_state)

        study_ids = Version.pluck('DISTINCT(study_id)').compact
        puts "Migrating studies: #{study_ids.inspect}"
        study_ids.each do |study_id|
          puts "Migrating study #{study_id}"
          config_history = study_configurations(study_id)
          migrate_study(study_id, config_history)
        end
      ensure
        PaperTrail.enabled = true
        ActiveRecord::Base.record_timestamps = true
        RequiredSeries.set_callback(:commit, :after, :schedule_domino_sync)
        RequiredSeries.set_callback(:save, :after, :update_image_series_state)
      end

      def migrated_configs(study_id)
        @migrated_configs ||=
          begin
            if File.exists?('study_config_migration.yml')
              JSON.parse(File.read('study_config_migration.yml'))
            else
              {}
            end
          end
        @migrated_configs[study_id.to_s] ||= []
      end

      def migrated_config?(study_id, time)
        migrated_configs(study_id).include?(time.as_json)
      end

      def save_migrated_config(study_id, time)
        migrated_configs(study_id).push(time)
        File.open('study_config_migration.yml', 'w+') do |file|
          file.write(@migrated_configs.to_json)
        end
      end

      def migrate_study(study_id, config_history)
        current_config = {}
        versions =
          Version
            .where(item_type: 'Visit', study_id: study_id)
            .where(migrated_required_series: false)
            .order(created_at: :asc)

        puts "Loading visit versions for study #{study_id}"
        progress = ProgressBar.create(
          title: 'Visit Versions',
          total: versions.count,
          format: '%t |%B| %a / %E (%c / %C ~ %p%%)'
        )
        versions.find_each do |version|
          Version.transaction do
            while config_history.first && version.created_at >= config_history.first[:time]
              puts "Version created (#{version.created_at.as_json}) >= #{config_history.first[:time].as_json}"
              config_change = config_history.shift
              previous_config = current_config
              current_config = config_change[:yaml]
              if migrated_config?(study_id, config_change[:time])
                puts ' => skipping; already done'
              else
                puts ' => Migrating Config Change'
                migrate_config_change(
                  study_id,
                  config_change[:time],
                  previous_config,
                  current_config,
                  whodunnit: 'config_change'
                )
              end
            end
            migrate_visit_destroy(version) if version.event == 'destroy'
            if version.object_changes.andand['visit_type'].andand[1].present?
              migrate_visit_type_change(version, current_config)
            end
            if version.object_changes.andand['required_series'].present?
              migrate_required_series_change(version, current_config)
            end

            version.migrated_required_series = true
            version.save!
          end
          progress.increment
        end
        while config_history.first.present?
          puts "Configuration update #{config_history.first[:time].as_json}"
          config_change = config_history.shift
          previous_config = current_config
          current_config = config_change[:yaml]
          if migrated_config?(study_id, config_change[:time])
            puts ' => skipping; already done'
          else
            puts ' => Migrating Config Change'
            migrate_config_change(
              study_id,
              config_change[:time],
              previous_config,
              current_config,
              whodunnit: 'config_change'
            )
          end
        end
      end

      def study_configurations(study_id)
        puts "Loading study configuration changes for study #{study_id}"
        merged_study_configurations(
          study_configuration_commits(study_id),
          study_configuration_locks(study_id)
        )
      end

      def study_configuration_commits(study_id)
        repo = GitConfigRepository.new
        config_path = Rails.application.config.study_configs_subdirectory + "/#{study_id}.yml"
        commits = repo.commits_for_file(config_path)
        commits.map do |commit|
          {
            ref: commit.oid,
            time: commit.time,
            yaml: repo.yaml_at_version(config_path, commit.oid)
          }
        end.sort_by { |commit| commit[:time] }
      end

      def study_configuration_locks(study_id)
        Version
          .where(item_type: 'Study', item_id: study_id)
          .where('(object_changes ->> \'locked_version\') IS NOT NULL')
          .order(created_at: :asc)
          .map do |version|
          {
            time: version.created_at,
            locked_version: version.object_changes['locked_version'].andand[1]
          }
        end
      end

      def merged_study_configurations(commits, locks)
        repo = GitConfigRepository.new
        configs = []
        locked_version = nil
        commits.each do |commit|
          if locks.first.present? && commit[:time] > locks.first[:time]
            version = locks.shift
            if version[:locked_version]
              locked_version = version[:locked_version]
              if locked_version.present? && configs.last.andand[:ref] != locked_version
                configs.push(
                  ref: locked_version,
                  time: version[:time],
                  yaml: repo.yaml_at_version(locked_version)
                )
              end
            else
              if locked_version.present?
                latest_commit = nil
                commits.each do |commit|
                  if commit[:time] > version[:time]
                    configs.push(
                      ref: latest_commit[:ref],
                      time: version[:time],
                      yaml: latest_commit[:yaml]
                    )
                    break
                  end
                  latest_commit = commit
                end
                locked_version = nil
              end
            end
          end
          configs.push(commit) if locked_version.nil?
        end
        configs
      end

      def migrate_config_change(study_id, time, previous_config, current_config, whodunnit: nil)
        old_visit_types = previous_config.andand['visit_types'].try(:keys) || []
        new_visit_types = current_config.andand['visit_types'].try(:keys) || []

        # Visit types added to the configuration. Look for visits that
        # need to be updated with the new required series.
        (new_visit_types - old_visit_types).each do |visit_type|
          config_change_added_visit_type(study_id, time, visit_type, current_config, whodunnit: whodunnit)
        end
        # Visit types removed from the configuration. Remove any
        # existing required series.
        (old_visit_types - new_visit_types).each do |visit_type|
          config_change_removed_visit_type(study_id, time, visit_type, previous_config, whodunnit: whodunnit)
        end
        # Visit types kept but maybe updated. Look for added or
        # removed required series and migrate changes.
        (old_visit_types & new_visit_types).each do |visit_type|
          config_change_modified_visit_type(study_id, time, visit_type, previous_config, current_config, whodunnit: whodunnit)
        end

        save_migrated_config(study_id, time)
      end

      def config_change_added_visit_type(study_id, time, visit_type, current_config, whodunnit: nil)
        rs_names = current_config.andand['visit_types'].andand[visit_type].andand['required_series'].try(:keys) || []
        visits_with_visit_type(study_id, visit_type, time).each do |visit_id|
          required_series_added(study_id, visit_id, time, rs_names, whodunnit: whodunnit)
        end
      end

      def visits_with_visit_type(study_id, visit_type, time)
        Version
          .where(item_type: 'Visit')
          .where(study_id: study_id)
          .where('created_at <= ?', time)
          .where('((object_changes ->> \'visit_type\')::jsonb ->> 1) = ?', visit_type)
          .distinct
          .pluck(:item_id)
      end

      def config_change_removed_visit_type(study_id, time, visit_type, previous_config, whodunnit: nil)
        rs_names = previous_config.andand['visit_types'].andand[visit_type].andand['required_series'].try(:keys) || []
        remove_required_series_for_visit_type(study_id, time, visit_type, rs_names, whodunnit: whodunnit)
      end

      def config_change_modified_visit_type(study_id, time, visit_type, previous_config, current_config, whodunnit: nil)
        old_rs = previous_config.andand['visit_types'].andand[visit_type].andand['required_series'].try(:keys) || []
        new_rs = current_config.andand['visit_types'].andand[visit_type].andand['required_series'].try(:keys) || []

        # Removed RequiredSeries
        remove_required_series_for_visit_type(study_id, time, visit_type , (old_rs - new_rs), whodunnit: whodunnit)
        # Added RequiredSeries
        visits_with_visit_type(study_id, visit_type, time).each do |visit_id|
          required_series_added(study_id, visit_id, time , (new_rs - old_rs), whodunnit: whodunnit)
        end
      end

      def required_series_added(study_id, visit_id, time, rs_names, whodunnit: nil)
        rs_names.each do |name|
          next if RequiredSeries.where(visit_id: visit_id, name: name).exists?
          required_series =
            RequiredSeries.create!(
              visit_id: visit_id,
              name: name,
              created_at: time,
              updated_at: time
            )
          Version.create!(
            item_type: 'RequiredSeries',
            item_id: required_series.id,
            event: 'create',
            object: nil,
            object_changes: {
              visit_id: [nil, visit_id],
              name: [nil, name],
              created_at: [nil, time.as_json],
              updated_at: [nil, time.as_json]
            },
            whodunnit: whodunnit,
            created_at: time.to_datetime,
            updated_at: time.to_datetime,
            study_id: study_id
          )
        end
      end

      def remove_required_series_for_visit_type(study_id, time, visit_type, required_series, whodunnit: nil)
        return if required_series.empty?
        visit_ids = Version
                      .where(item_type: 'Visit')
                      .where(study_id: study_id)
                      .where('created_at <= ?', time)
                      .where('((object_changes ->> \'visit_type\')::jsonb ->> 1) = ?', visit_type)
                      .distinct
                      .pluck(:item_id)
        RequiredSeries
          .where(visit_id: visit_ids, name: required_series)
          .where('created_at < ?', time)
          .find_each do |rs|
          destroy_required_series(study_id, time, rs, whodunnit: whodunnit)
        end
      end

      def migrate_visit_destroy(version)
        RequiredSeries.where(visit_id: version.item_id).each do |required_series|
          destroy_required_series(version.study_id, version.created_at, required_series)
        end
      end

      def migrate_visit_type_change(version, current_config)
        was, becomes = version.object_changes.andand['visit_type']
        puts "Migrate visit type change: #{was} => #{becomes}"
        old_rs = current_config['visit_types'].andand[was].andand['required_series'].try(:keys) || []
        new_rs = current_config['visit_types'].andand[becomes].andand['required_series'].try(:keys) || []

        create_required_series_presets(version, (new_rs - old_rs))
        remove_required_series_presets(version, (old_rs - new_rs))
      end

      def create_required_series_presets(version, required_series_names)
        puts "Create Required Series Presets: #{required_series_names.join(',')}"
        required_series_names.each do |name|
          puts "--- Checking existing required series"
          next if RequiredSeries.where(visit_id: version.item_id, name: name).exists?
          puts "--- Creating required series"
          required_series =
            RequiredSeries.create!(
              visit_id: version.item_id,
              name: name,
              created_at: version.created_at,
              updated_at: version.created_at
            )
          puts "--- Creating required series version"
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
            whodunnit: version.whodunnit,
            created_at: version.created_at,
            updated_at: version.created_at,
            study_id: version.study_id
          )
        end
      end

      def remove_required_series_presets(version, required_series_names)
        puts "Remove Required Series Presets: #{required_series_names.join(',')}"
        required_series_names.each do |name|
          required_series = RequiredSeries.where(visit_id: version.item_id, name: name).first
          next if required_series.blank?
          destroy_required_series(version.study_id, version.created_at, required_series)
        end
      end

      def destroy_required_series(study_id, destroyed_at, required_series, whodunnit: nil)
        puts "Destroy required series #{required_series.visit_id} - #{required_series.name}"
        puts "--- creating destroy version"
        Version.create!(
          item_type: 'RequiredSeries',
          item_id: required_series.id,
          event: 'destroy',
          object: JSON.parse(required_series.to_json),
          object_changes: nil,
          created_at: destroyed_at,
          updated_at: destroyed_at,
          study_id: study_id,
          whodunnit: whodunnit
        )
        puts "--- destroying required series"
        required_series.destroy!
      end

      def migrate_required_series_change(version, current_config)
        puts "Migrate required series change"
        required_series_changes(version).each do |mapping|
          create_required_series_version(version, **mapping)
        end
      end

      def create_required_series_version(visit_version, visit_id:, name:, changes:)
        puts "Creating required series version #{visit_id} - #{name}"
        puts "--- Finding latest required series version"
        latest_version = find_latest_required_series_version(visit_version.study_id, visit_id, name)
        binding.pry if latest_version.nil?
        puts "--- Extracting non-obsolete changes"
        changes = non_obsolete_changes(latest_version, visit_version, changes)
        puts "--- Checking if required series version exists"
        return if Version.where(created_at: visit_version.created_at, item_id: latest_version.item_id, item_type: 'RequiredSeries').exists?
        return if changes.blank?
        puts "--- Creating version"
        Version.create!(
          item_type: 'RequiredSeries',
          item_id: latest_version.item_id,
          event: 'update',
          object: latest_version.complete_attributes,
          object_changes: changes,
          created_at: visit_version.created_at,
          whodunnit: visit_version.whodunnit,
          study_id: visit_version.study_id
        )
        puts "--- Checking existing required series "
        required_series = RequiredSeries.where(id: latest_version.item_id).first
        return if required_series.nil?
        attributes = changes.transform_values { |_, new| new }
        puts "--- Updating existing required series"
        required_series.update_attributes(attributes)
        required_series.save!
        puts "--- Updating done"
      end

      def find_latest_required_series_version(study_id, visit_id, name)
        Version
          .where(item_type: 'RequiredSeries', study_id: study_id)
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

      def non_obsolete_changes(latest_version, visit_version, changes)
        complete_attributes = latest_version.complete_attributes
        changes = changes.delete_if do |col, (_, became)|
          complete_attributes.andand[col] == became
        end
        changes.delete('tqc_state') if complete_attributes['tqc_state'].nil? && changes.dig('image_series_id', 1).nil?
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
            changes: extract_changes(visit_version, required_series_name)
          }
        end
      end

      def extract_changes(visit_version, required_series_name)
        was, becomes = visit_version.complete_changes['required_series']
        changes = {}
        RequiredSeries.columns.map do |column|
          was_value = was.dig2(required_series_name, column.name)
          becomes_value = becomes.dig2(required_series_name, column.name)
          next if was_value == becomes_value
          if column.name == 'tqc_state'
            enum = RequiredSeries.defined_enums[column.name].invert
            changes[column.name] ||= [enum[was_value], enum[becomes_value]]
          elsif column.name == 'image_series_id'
            changes[column.name] = [was_value.andand.to_i, becomes_value.andand.to_i]
            if was_value.blank? && becomes_value.present?
              changes['tqc_state'] = [nil, 'pending']
            elsif was_value.present? && becomes_value.blank?
              enum = RequiredSeries.defined_enums['tqc_state'].invert
              state_value = was.dig2(required_series_name, 'tqc_state')
              changes['tqc_state'] = [enum[state_value], nil] if enum[state_value].present?
            end
          elsif column.name == 'tqc_date'
            changes[column.name] = [
              was_value.present? ? DateTime.parse(was_value) : nil,
              becomes_value.present? ? DateTime.parse(becomes_value) : nil
            ]
          else
            changes[column.name] = [was_value, becomes_value]
          end
        end.compact
        changes
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

      def study_config_path(id)
        Rails.application.config.study_configs_subdirectory + "/#{id}.yml"
      end
    end
  end
end
