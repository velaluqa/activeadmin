module Visit::Operation
  class ConsolidateStudyConfiguration < Trailblazer::Operation
    step :extract_params

    ##
    # Currently we have to skip these functions. Otherwise we would do
    # with the callbacks, what the operation is supposed to do. Later we
    # want to get rid of the callbacks alltogether and invoke the worker
    # calling the operation asynchronously.
    #
    # TODO: Create tests for the behavior of the callbacks.
    # TODO: Invoke operation instead of current callback procedures.
    step(
      Wrap(
        ->((ctx, flow_options), *, &block) {
          Visit.skip_callback(:save, :after, :update_required_series_preset)
          block.call
          Visit.set_callback(:save, :after, :update_required_series_preset)
          true
        }
      ) {
        step :unset_obsolete_visit_type
        step :reset_mqc_for_updated_spec
        step :create_missing_required_series
        step :remove_obsolete_required_series
        step :reset_tqc_for_updated_required_series
      }
    )

    def extract_params(ctx, params:, **)
      ctx[:changes] ||= { added: [], removed: [] }
      ctx[:dry_run] = params[:dry_run] || false
      ctx[:visit] = visit = Visit.find(params[:visit_id])
      ctx[:version] = version = params[:version]
      ctx[:version_hash] = visit.study.version_hash(version: version)

      true
    end

    def unset_obsolete_visit_type(ctx, dry_run:, visit:, version_hash:, **)
      visit_type_spec = visit.study.visit_type_spec(version: version_hash)

      expected_visit_types = visit_type_spec&.keys || []

      return true if expected_visit_types.include?(visit.visit_type)

      ctx[:changes][:removed].push(
        visit_id: visit.id,
        message: "Unsetting visit type '#{visit.visit_type}'"
      )

      return true if dry_run

      visit.visit_type = nil
      # visit.reset_mqc
      visit.save!

      true
    end

    def reset_mqc_for_updated_spec(ctx, dry_run:, visit:, version_hash:, **)
      return true if visit.mqc_state_sym == :pending
      return true if visit.mqc_version == version_hash

      visit_type_spec = visit.study.visit_type_spec(version: version_hash)

      new_spec = visit_type_spec.andand[visit.visit_type].andand['mqc']
      mqc_spec = visit.mqc_version && visit.study.visit_type_spec(version: visit.mqc_version)[visit.visit_type]['mqc']

      return true if new_spec.present? && new_spec == mqc_spec

      ctx[:changes][:removed].push(
        visit_id: visit.id,
        message: "Resetting mQC due to changed mQC specification"
      )

      return true if dry_run

      visit.reset_mqc

      true
    end

    def create_missing_required_series(ctx, dry_run:, visit:, version_hash:, **)
      required_series_spec = visit.required_series_spec(version: version_hash)

      required_series_spec.keys.each do |name|
        required_series = visit.required_series.where(name: name).first

        next if required_series

        ctx[:changes][:added].push(
          visit_id: visit.id,
          message: "Creating required series '#{name}'"
        )

        next if dry_run

        visit.required_series.create(name: name)
      end

      true
    end

    def remove_obsolete_required_series(ctx, dry_run:, visit:, version_hash:, **)
      return true unless visit.required_series.exists?

      required_series_spec = visit.required_series_spec(version: version_hash)

      existing_required_series = visit.required_series.pluck(:name)
      obsolete_required_series = existing_required_series - required_series_spec.keys

      return true if obsolete_required_series.empty?

      obsolete_required_series.each do |name|
        ctx[:changes][:removed].push(
          visit_id: visit.id,
          message: "Removing obsolete required series '#{name}'"
        )
      end

      return true if dry_run

      visit
        .required_series
        .where('name IN (?)', obsolete_required_series)
        .destroy_all

      true
    end

    def reset_tqc_for_updated_required_series(ctx, dry_run:, visit:, version_hash:, **)
      visit.required_series.each do |series|
        next unless %w[passed issues].include?(series.tqc_state)
        next if series.tqc_version == version_hash

        new_spec = series.tqc_spec(version: version_hash)
        tqc_spec = series.tqc_version && series.tqc_spec(version: series.tqc_version)

        next if new_spec.present? && new_spec == tqc_spec

        ctx[:changes][:removed].push(
          visit_id: visit.id,
          message: "Resetting tQC results for required series '#{series.name}'"
        )

        next if dry_run

        series.reset_tqc!
      end

      true
    end
  end
end
