require 'report/overview'

describe Report::Overview do
  describe 'given columns: "all"' do
    let!(:study1) { create(:study) }
    let!(:center1) { create(:center, study: study1) }
    let!(:patient1) { create(:patient, center: center1) }
    let!(:visit1) { create(:visit, patient: patient1) }
    let!(:image_series1) { create(:image_series, patient: patient1)}
    let!(:role) { create(:role, with_permissions: { Study => :read_reports }) }
    let!(:user) { create(:user, with_user_roles: [role]) }
    let!(:report) { Report::Overview.new(columns: 'all', user: user) }

    it 'returns all available columns' do
      result = report.result.first[:columns]
      expect(result).to include(name: 'patients', value: 1)
      expect(result).to include(name: 'visits', value: 1)
      expect(result).to include(name: 'visits_state_incomplete_na', value: 1)
      expect(result).to include(name: 'visits_state_incomplete_queried', value: 0)
      expect(result).to include(name: 'visits_state_complete_tqc_pending', value: 0)
      expect(result).to include(name: 'visits_state_complete_tqc_issues', value: 0)
      expect(result).to include(name: 'visits_state_complete_tqc_passed', value: 0)
      expect(result).to include(name: 'image_series', value: 1)
      expect(result).to include(name: 'required_series', value: 0)
      expect(result).to include(name: 'required_series_state_pending', value: 0)
      expect(result).to include(name: 'required_series_state_issues', value: 0)
      expect(result).to include(name: 'required_series_state_passed', value: 0)
    end
  end

  describe 'user report' do
    let!(:study1) { create(:study) }
    let!(:center1) { create(:center, study: study1) }
    let!(:patient1) { create(:patient, center: center1) }
    let!(:patient2) { create(:patient, center: center1) }
    let!(:study2) { create(:study) }
    let!(:center2) { create(:center, study: study2) }
    let!(:patient3) { create(:patient, center: center2) }
    let!(:patient4) { create(:patient, center: center2) }

    describe 'for user with full access' do
      let!(:role) { create(:role, with_permissions: { Study => :read_reports }) }
      let!(:user) { create(:user, with_user_roles: [role]) }
      let!(:report) { Report::Overview.new(columns: %w(patients), user: user) }

      it 'shows all studies' do
        report_studies = report.result.map { |study| study[:study_id] }
        expect(report_studies).to include(study1.id)
        expect(report_studies).to include(study2.id)
      end
    end

    describe 'for user limited access' do
      let!(:role) { create(:role, with_permissions: { Study => :read_reports }) }
      let!(:user) { create(:user, with_user_roles: [[role, study1]]) }
      let!(:report) { Report::Overview.new(columns: %w(patients), user: user) }

      it 'shows all studies' do
        report_studies = report.result.map { |study| study[:study_id] }
        expect(report_studies).to include(study1.id)
        expect(report_studies).not_to include(study2.id)
      end
    end

    describe 'for user without `read_reports` permission' do
      let!(:role) { create(:role, with_permissions: { Study => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, study1]]) }
      let!(:report) { Report::Overview.new(columns: %w(patients), user: user) }

      it 'shows all studies' do
        report_studies = report.result.map { |study| study[:study_id] }
        expect(report_studies).not_to include(study1.id)
        expect(report_studies).not_to include(study2.id)
      end
    end

    describe 'for user with permission one specific center' do
      let!(:role) { create(:role, with_permissions: { Study => :read_reports }) }
      let!(:user) { create(:user, with_user_roles: [[role, center1]]) }
      let!(:report) { Report::Overview.new(columns: %w(patients), user: user) }

      it 'shows all studies' do
        report_studies = report.result.map { |study| study[:study_id] }
        expect(report_studies).to include(study1.id)
        expect(report_studies).not_to include(study2.id)
      end
    end
  end

  describe 'with patients column' do
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient1) { create(:patient, center: center) }
    let!(:patient2) { create(:patient, center: center) }

    it 'it displays the current patient count' do
      report = Report::Overview.new(
        columns: %w(patients)
      )
      study_report = {
        study_id: study.id,
        study_name: study.name,
        columns: [{ name: 'patients', value: 2 }]
      }
      expect(report.result).to include(study_report)
    end
  end

  describe 'with visits column' do
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient1) { create(:patient, center: center) }
    let!(:visit1) { create(:visit, patient: patient1) }
    let!(:patient2) { create(:patient, center: center) }
    let!(:visit2) { create(:visit, patient: patient2) }
    let!(:visit3) { create(:visit, patient: patient2) }

    it 'it displays the current visits count' do
      report = Report::Overview.new(
        columns: %w(visits)
      )
      study_report = {
        study_id: study.id,
        study_name: study.name,
        columns: [{ name: 'visits', value: 3 }]
      }
      expect(report.result).to include(study_report)
    end
  end

  describe 'with visit state columns' do
    describe 'incomplete_na' do
      let!(:study) { create(:study) }
      let!(:center) { create(:center, study: study) }
      let!(:patient1) { create(:patient, center: center) }
      let!(:visit1) { create(:visit, patient: patient1) }
      let!(:visit2) { create(:visit, patient: patient1, state: :complete_tqc_passed) }
      let!(:visit3) { create(:visit, patient: patient1, state: :complete_tqc_passed) }
      let!(:visit4) { create(:visit, patient: patient1, state: :complete_tqc_issues) }
      let!(:visit5) { create(:visit, patient: patient1, state: :complete_tqc_pending) }
      let!(:patient2) { create(:patient, center: center) }
      let!(:visit6) { create(:visit, patient: patient2, state: :incomplete_na) }
      let!(:visit7) { create(:visit, patient: patient2, state: :incomplete_queried) }

      it 'it displays the current visit state counts' do
        report = Report::Overview.new(
          columns: %w(visits_state_incomplete_na visits_state_incomplete_queried visits_state_complete_tqc_pending visits_state_complete_tqc_issues visits_state_complete_tqc_passed)
        )
        study_report = {
          study_id: study.id,
          study_name: study.name,
          columns: [
            { name: 'visits_state_incomplete_na', value: 2 },
            { name: 'visits_state_incomplete_queried', value: 1 },
            { name: 'visits_state_complete_tqc_pending', value: 1 },
            { name: 'visits_state_complete_tqc_issues', value: 1 },
            { name: 'visits_state_complete_tqc_passed', value: 2 }
          ]
        }
        expect(report.result).to include(study_report)
      end
    end
  end

  describe 'with image_series column' do
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient1) { create(:patient, center: center) }
    let!(:image_series1) { create(:image_series, patient: patient1)}
    let!(:patient2) { create(:patient, center: center) }
    let!(:image_series2) { create(:image_series, patient: patient2)}

    it 'it displays the current image_series count' do
      report = Report::Overview.new(
        columns: %w(image_series)
      )
      study_report = {
        study_id: study.id,
        study_name: study.name,
        columns: [{ name: 'image_series', value: 2 }]
      }
      expect(report.result).to include(study_report)
    end
  end

  describe 'with required_series column' do
    let!(:user) { create(:user) }
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient1) { create(:patient, center: center) }
    let!(:image_series1) { create(:image_series, patient: patient1)}
    let!(:image_series2) { create(:image_series, patient: patient1)}
    let!(:visit) do
      assigned_image_series_index = {
        image_series1.id.to_s => ['chest'],
        image_series2.id.to_s => ['abdomen']
      }
      required_series = {
        'chest' => {
          'image_series_id' => image_series1.id.to_s,
          'tqc_state' => 2
        },
        'abdomen'=>{
          'image_series_id' => image_series2.id.to_s,
          'tqc_state' => 2
        },
        'additional' => {}
      }
      create(
        :visit,
        patient: patient1,
        assigned_image_series_index: assigned_image_series_index,
        required_series: required_series
      )
    end

    it 'displays the correct required series count' do
      report = Report::Overview.new(
        columns: %w(required_series)
      )
      expected_result = {
        study_id: study.id,
        study_name: study.name,
        columns: [{ name: 'required_series', value: 2 }]
      }
      expect(report.result).to include(expected_result)
    end
  end

  describe 'with required_series state column' do
    let!(:user) { create(:user) }
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient1) { create(:patient, center: center) }
    let!(:image_series1) { create(:image_series, patient: patient1)}
    let!(:image_series2) { create(:image_series, patient: patient1)}
    let!(:visit1) do
      create(
        :visit,
        patient: patient1,
        assigned_image_series_index: {
          image_series1.id.to_s => ['chest'],
          image_series2.id.to_s => ['abdomen']
        },
        required_series: {
          'chest' => {
            'image_series_id' => image_series1.id.to_s,
            'tqc_state' => 0
          },
          'abdomen'=>{
            'image_series_id' => image_series2.id.to_s,
            'tqc_state' => 1
          },
          'additional' => {
            'image_series_id' => image_series2.id.to_s,
            'tqc_state' => 1
          }
        }
      )
    end
    let!(:visit2) do
      create(
        :visit,
        patient: patient1,
        assigned_image_series_index: {
          image_series1.id.to_s => ['chest'],
          image_series2.id.to_s => ['abdomen']
        },
        required_series: {
          'chest' => {
            'image_series_id' => image_series1.id.to_s,
            'tqc_state' => 2
          },
          'abdomen'=>{
            'image_series_id' => image_series2.id.to_s,
            'tqc_state' => 2
          },
          'additional' => {
            'image_series_id' => image_series2.id.to_s,
            'tqc_state' => 2
          }
        }
      )
    end

    it 'displays the correct required series count' do
      report = Report::Overview.new(
        columns: %w(required_series_state_pending required_series_state_issues required_series_state_passed)
      )
      expected_result = {
        study_id: study.id,
        study_name: study.name,
        columns: [
          { name: 'required_series_state_pending', value: 1 },
          { name: 'required_series_state_issues', value: 2 },
          { name: 'required_series_state_passed', value: 3 }
        ]
      }
      expect(report.result).to include(expected_result)
    end
  end
end
