module Report
  # Calculates report values for a given array of values and all
  # studies a given user has the permissions to `read_reports` for.
  class Overview
    AVAILABLE_COLUMNS = %w[
      patients
      visits
      visits_state_incomplete_na
      visits_state_incomplete_queried
      visits_state_complete_tqc_pending
      visits_state_complete_tqc_issues
      visits_state_complete_tqc_passed
      image_series
      required_series
      required_series_unassigned
      required_series_state_pending
      required_series_state_issues
      required_series_state_passed
    ].freeze

    attr_reader :study_ids, :user

    def initialize(options)
      @columns = options[:columns]
      @study_ids = options[:study_ids]
      @user = options[:user]
    end

    def result
      {
        columns: columns,
        studies: study_results
      }
    end

    def columns
      return @columns if @columns.is_a?(Array)
      AVAILABLE_COLUMNS
    end

    private

    def study_results
      @study_results ||= study_scope.map do |study|
        {
          study_id: study.id,
          study_name: study.name,
          columns: columns.map do |column|
            column_value(study, column)
          end
        }
      end
    end

    # If the report is generated for a given user, we want to limit
    # the study list to only those studies the user has appropriate
    # access to.
    def study_scope
      return Study.all if user.nil?

      Study.granted_for(
        user: user,
        activity: 'read_reports'
      )
    end

    def column_value(study, column)
      return unless AVAILABLE_COLUMNS.include?(column)
      send("#{column}_column_value", study)
    end

    def patients_column_value(study)
      study.patients.count
    end

    def visits_column_value(study)
      study.visits.count
    end

    def visits_state_incomplete_na_column_value(study)
      study.visits.with_state(:incomplete_na).count
    end

    def visits_state_incomplete_queried_column_value(study)
      study.visits.with_state(:incomplete_queried).count
    end

    def visits_state_complete_tqc_pending_column_value(study)
      study.visits.with_state(:complete_tqc_pending).count
    end

    def visits_state_complete_tqc_issues_column_value(study)
      study.visits.with_state(:complete_tqc_issues).count
    end

    def visits_state_complete_tqc_passed_column_value(study)
      study.visits.with_state(:complete_tqc_passed).count
    end

    def image_series_column_value(study)
      study.image_series.count
    end

    def required_series(study)
      @required_series ||= {}
      @required_series[study.id] ||=
        study
          .required_series
          .group(:tqc_state)
          .count
    end

    def required_series_column_value(study)
      required_series(study).inject(0) { |agg, (_, val)| agg + val }
    end

    def required_series_unassigned_column_value(study)
      required_series(study)[nil] || 0
    end

    def required_series_state_pending_column_value(study)
      required_series(study)['pending'] || 0
    end

    def required_series_state_issues_column_value(study)
      required_series(study)['issues'] || 0
    end

    def required_series_state_passed_column_value(study)
      required_series(study)['passed'] || 0
    end
  end
end
