class Visit::ConsolidateStudyConfiguration < Trailblazer::Operation
  step :extract_params
  step :unset_obsolete_visit_type
  step :create_missing_required_series
  step :remove_obsolete_required_series
  step :reset_tqc_for_updated_required_series

  def extract_params(ctx, params:, **)
    ctx[:visit] = visit = Visit.find(params[:visit_id])
    ctx[:version] = version = params[:version]
    ctx[:version_hash] = version_hash = visit.study.version_hash(version: version_hash)
    ctx[:visit_type_spec] = visit.study.visit_type_spec(version: version_hash)
    ctx[:required_series_spec] = visit.required_series_spec(version: version_hash)
    true
  end

  def unset_obsolete_visit_type(_, visit:, visit_type_spec:, **)
    expected_visit_types = visit_type_spec&.keys || []

    unless expected_visit_types.include?(visit.visit_type)
      visit.visit_type = nil
      visit.save!
    end
    true
  end

  def create_missing_required_series(ctx, visit:, required_series_spec:, **)
    required_series_spec.keys.each do |name|
      visit.required_series.where(name: name).first_or_create
    end
    true
  end

  def remove_obsolete_required_series(ctx, visit:, required_series_spec:, **)
    return true unless visit.required_series.exists?

    existing_required_series = visit.required_series.pluck(:name)
    obsolete_required_series = existing_required_series - required_series_spec.keys

    return true if obsolete_required_series.empty?
    visit
      .required_series
      .where('name IN (?)', obsolete_required_series)
      .destroy_all
    true
  end

  def reset_tqc_for_updated_required_series(ctx, visit:, version_hash:, **)
    visit.required_series.each do |series|
      next unless %w[passed issues].include?(series.tqc_state)
      next if series.tqc_version == version_hash

      new_spec = series.tqc_spec(version: version_hash)
      tqc_spec = series.tqc_spec(version: series.tqc_version)

      series.reset_tqc! if series.tqc_version.nil? || new_spec != tqc_spec
      true
    end
  end
end
