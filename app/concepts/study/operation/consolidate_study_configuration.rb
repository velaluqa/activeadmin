module Study::Operation
  class ConsolidateStudyConfiguration < Trailblazer::Operation # :nodoc:
    step :extract_params
    step :consolidate_visits

    def extract_params(ctx, params:, **)
      ctx[:changes] ||= { added: [], removed: [] }
      ctx[:dry_run] = params[:dry_run] || false
      ctx[:study] = study = Study.find(params[:study_id])
      ctx[:version] = version = params[:version]
      ctx[:visit_type_spec] = study.visit_type_spec(version: version)
      true
    end

    def consolidate_visits(ctx, study:, dry_run:, version:, **)
      study.visits.pluck(:id).each do |visit_id|
        result = Visit::Operation::ConsolidateStudyConfiguration.(
          params: {
            visit_id: visit_id,
            version: version,
            dry_run: dry_run
          }
        )
        ctx[:changes][:added].push(*result[:changes][:added])
        ctx[:changes][:removed].push(*result[:changes][:removed])
      end
      true
    end
  end
end
