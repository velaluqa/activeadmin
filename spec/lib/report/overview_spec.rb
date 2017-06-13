require 'report/overview'

describe Report::Overview do
  describe 'given columns: "all"' do
    let!(:study1) { create(:study) }
    let!(:center1) { create(:center, study: study1) }
    let!(:patient1) { create(:patient, center: center1) }
    let!(:visit1) { create(:visit, patient: patient1) }
    let!(:image_series1) { create(:image_series, patient: patient1) }
    let!(:role) { create(:role, with_permissions: { Study => :read_reports }) }
    let!(:user) { create(:user, with_user_roles: [role]) }
    let!(:report) { Report::Overview.new(columns: 'all', user: user) }

    it 'returns all available columns' do
      result = report.result[:studies].first[:columns]
      expect(result).to eq [1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0]
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
      let!(:report) { Report::Overview.new(columns: %w[patients], user: user) }

      it 'shows all studies' do
        report_studies = report.result[:studies].map { |study| study[:study_id] }
        expect(report_studies).to include(study1.id)
        expect(report_studies).to include(study2.id)
      end
    end

    describe 'for user limited access' do
      let!(:role) { create(:role, with_permissions: { Study => :read_reports }) }
      let!(:user) { create(:user, with_user_roles: [[role, study1]]) }
      let!(:report) { Report::Overview.new(columns: %w[patients], user: user) }

      it 'shows all studies' do
        report_studies = report.result[:studies].map { |study| study[:study_id] }
        expect(report_studies).to include(study1.id)
        expect(report_studies).not_to include(study2.id)
      end
    end

    describe 'for user without `read_reports` permission' do
      let!(:role) { create(:role, with_permissions: { Study => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, study1]]) }
      let!(:report) { Report::Overview.new(columns: %w[patients], user: user) }

      it 'shows all studies' do
        report_studies = report.result[:studies].map { |study| study[:study_id] }
        expect(report_studies).not_to include(study1.id)
        expect(report_studies).not_to include(study2.id)
      end
    end

    describe 'for user with permission one specific center' do
      let!(:role) { create(:role, with_permissions: { Study => :read_reports }) }
      let!(:user) { create(:user, with_user_roles: [[role, center1]]) }
      let!(:report) { Report::Overview.new(columns: %w[patients], user: user) }

      it 'shows all studies' do
        report_studies = report.result[:studies].map { |study| study[:study_id] }
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
    let!(:result) do
      report = Report::Overview.new(columns: %w[patients])
      report.result[:studies]
    end

    it 'it displays the current patient count' do
      study_report = {
        study_id: study.id,
        study_name: study.name,
        columns: [2]
      }
      expect(result).to include(study_report)
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
    let!(:result) do
      report = Report::Overview.new(columns: %w[visits])
      report.result[:studies]
    end

    it 'it displays the current visits count' do
      study_report = {
        study_id: study.id,
        study_name: study.name,
        columns: [3]
      }
      expect(result).to include(study_report)
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
      let!(:result) do
        report = Report::Overview.new(
          columns: %w[visits_state_incomplete_na visits_state_incomplete_queried visits_state_complete_tqc_pending visits_state_complete_tqc_issues visits_state_complete_tqc_passed]
        )
        report.result[:studies]
      end

      it 'it displays the current visit state counts' do
        study_report = {
          study_id: study.id,
          study_name: study.name,
          columns: [2, 1, 1, 1, 2]
        }
        expect(result).to include(study_report)
      end
    end
  end

  describe 'with image_series column' do
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient1) { create(:patient, center: center) }
    let!(:image_series1) { create(:image_series, patient: patient1) }
    let!(:patient2) { create(:patient, center: center) }
    let!(:image_series2) { create(:image_series, patient: patient2) }
    let!(:result) do
      report = Report::Overview.new(columns: %w[image_series])
      report.result[:studies]
    end

    it 'it displays the current image_series count' do
      study_report = {
        study_id: study.id,
        study_name: study.name,
        columns: [2]
      }
      expect(result).to include(study_report)
    end
  end

  describe 'with required_series column' do
    let!(:user) { create(:user) }
    let!(:study) { create(:study, :locked, configuration: <<CONFIG.strip_heredoc) }
      visit_types:
        baseline:
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
      image_series_properties: []
CONFIG
    let!(:center) { create(:center, study: study) }
    let!(:patient1) { create(:patient, center: center) }
    let!(:image_series1) { create(:image_series, patient: patient1) }
    let!(:image_series2) { create(:image_series, patient: patient1) }
    let!(:visit) { create(:visit, patient: patient1, visit_type: 'baseline' ) }

    before(:each) do
      visit.change_required_series_assignment('SPECT_1' => image_series1.id)
      expect(visit.set_tqc_result('SPECT_1', {}, user, '')).to eq(true)
      visit.change_required_series_assignment('SPECT_2' => image_series1.id)
      expect(visit.set_tqc_result('SPECT_2', {}, user, '')).to eq(true)
    end

    let(:result) do
      report = Report::Overview.new(columns: %w[required_series])
      report.result[:studies]
    end

    it 'displays the correct required series count' do
      expected_result = {
        study_id: study.id,
        study_name: study.name,
        columns: [2]
      }
      expect(result).to include(expected_result)
    end
  end

  describe 'with required_series state column' do
    let!(:user) { create(:user) }
    let!(:study) { create(:study, :locked, configuration: <<CONFIG.strip_heredoc) }
      visit_types:
        baseline:
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
      image_series_properties: []
CONFIG
    let!(:center) { create(:center, study: study) }
    let!(:patient1) { create(:patient, center: center) }
    let!(:image_series1) { create(:image_series, patient: patient1) }
    let!(:image_series2) { create(:image_series, patient: patient1) }
    let!(:visit1) { create(:visit, patient: patient1, visit_type: 'baseline') }
    let!(:required_series11) { RequiredSeries.where(visit: visit1, name: 'SPECT_1').first }
    let!(:required_series12) { RequiredSeries.where(visit: visit1, name: 'SPECT_2').first }
    let!(:visit2) { create(:visit, patient: patient1, visit_type: 'baseline') }
    let!(:required_series21) { RequiredSeries.where(visit: visit2, name: 'SPECT_1').first }
    let!(:required_series22) { RequiredSeries.where(visit: visit2, name: 'SPECT_2').first }

    before(:each) do
      required_series11.update_attributes(tqc_state: 0)
      required_series12.update_attributes(tqc_state: 1)
      required_series21.update_attributes(tqc_state: 2)
      required_series22.update_attributes(tqc_state: 2)
    end

    let(:result) do
      report = Report::Overview.new(
        columns: %w[required_series_state_pending required_series_state_issues required_series_state_passed]
      )
      report.result[:studies]
    end

    it 'displays the correct required series count' do
      expected_result = {
        study_id: study.id,
        study_name: study.name,
        columns: [1, 1, 2]
      }
      expect(result).to include(expected_result)
    end
  end
end
