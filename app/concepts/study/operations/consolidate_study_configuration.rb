class Study::ConsolidateStudyConfiguration < Trailblazer::Operation # :nodoc:
  step :extract_params
  step :consolidate_visits

  def extract_params(ctx, params:, **)
    ctx[:study] = study = Study.find(params[:study_id])
    ctx[:version] = version = params[:version]
    ctx[:visit_type_spec] = study.visit_type_spec(version: version)
    true
  end

  def consolidate_visits(_, study:, version:, **)
    study.visits.pluck(:id).each do |visit_id|
      Visit::ConsolidateStudyConfiguration.call(
        visit_id: visit_id,
        version: version
      )
    end
    true
  end
end
