require 'record_search'

describe RecordSearch do
  describe '#new' do
    let!(:user) { create(:user) }
    let!(:search) do
      RecordSearch.new(
        user: user,
        query: 'foo',
        models: %w[Notification BackgroundJob Study Center Patient Visit ImageSeries Image]
      )
    end

    it 'initializes user, query and only allowed models' do
      expect(search.user).to eq user
      expect(search.query).to eq 'foo'
      expect(search.models).to eq %w[BackgroundJob Study Center Patient Visit ImageSeries Image]
    end
  end

  describe '#results' do
    let!(:study1) { create(:study, :locked, name: 'TestStudy1', configuration: <<CONFIG.strip_heredoc ) }
      image_series_properties: []
      visit_types:
        baseline:
          description: Some simple visit type
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
CONFIG
    let!(:center1) { create(:center, code: 'TestCenter1', study: study1) }
    let!(:patient1) { create(:patient, subject_id: 'TestPatient1', center: center1) }
    let!(:visit1) { create(:visit, visit_type: 'baseline', visit_number: 2, patient: patient1) }
    let!(:required_series11) { visit1.required_series.where(name: 'SPECT_1').first }
    let!(:required_series12) { visit1.required_series.where(name: 'SPECT_2').first }
    let!(:study2) { create(:study, :locked, name: 'TestStudy2', configuration: <<CONFIG.strip_heredoc ) }
      image_series_properties: []
      visit_types:
        baseline:
          description: Some simple visit type
          required_series:
            OTHER_1:
              tqc: []
            OTHER_2:
              tqc: []
CONFIG
    let!(:center2) { create(:center, code: 'TestCenter2', study: study2) }
    let!(:patient2) { create(:patient, subject_id: 'TestPatient2', center: center2) }
    let!(:visit2) { create(:visit, visit_type: 'baseline', visit_number: 2, patient: patient2) }
    let!(:required_series21) { visit2.required_series.where(name: 'OTHER_1').first }
    let!(:required_series22) { visit2.required_series.where(name: 'OTHER_2').first }
    let!(:user) { create(:user, is_root_user: true) }

    describe 'not filtering models' do
      let!(:search) do
        RecordSearch.new(
          user: user,
          query: 'Test'
        )
      end

      it 'returns matched records' do
        expect(search.results)
          .to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => 'TestStudy1',
            'result_id' => study1.id,
            'result_type' => 'Study'
          )
        expect(search.results)
          .to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => "TestCenter1 - #{center1.name}",
            'result_id' => center1.id,
            'result_type' => 'Center'
          )
        expect(search.results)
          .to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => 'TestCenter1TestPatient1',
            'result_id' => patient1.id,
            'result_type' => 'Patient'
          )
        expect(search.results)
          .to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => "TestCenter1TestPatient1##{visit1.visit_number}",
            'result_id' => visit1.id,
            'result_type' => 'Visit'
          )
        expect(search.results)
          .to include(
                'study_id' => study1.id,
                'study_name' => study1.name,
                'text' =>
                "TestCenter1TestPatient1##{visit1.visit_number} - SPECT_1",
                'result_id' => required_series11.id,
                'result_type' => 'RequiredSeries'
              )
        expect(search.results)
          .to include(
                'study_id' => study1.id,
                'study_name' => study1.name,
                'text' =>
                "TestCenter1TestPatient1##{visit1.visit_number} - SPECT_2",
                'result_id' => required_series12.id,
                'result_type' => 'RequiredSeries'
              )
        expect(search.results)
          .to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => 'TestStudy2',
            'result_id' => study2.id,
            'result_type' => 'Study'
          )
        expect(search.results)
          .to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => "TestCenter2 - #{center2.name}",
            'result_id' => center2.id,
            'result_type' => 'Center'
          )
        expect(search.results)
          .to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => 'TestCenter2TestPatient2',
            'result_id' => patient2.id,
            'result_type' => 'Patient'
          )
        expect(search.results)
          .to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => "TestCenter2TestPatient2##{visit2.visit_number}",
            'result_id' => visit2.id,
            'result_type' => 'Visit'
          )
        expect(search.results)
          .to include(
                'study_id' => study2.id,
                'study_name' => study2.name,
                'text' =>
                "TestCenter2TestPatient2##{visit2.visit_number} - OTHER_1",
                'result_id' => required_series21.id,
                'result_type' => 'RequiredSeries'
              )
        expect(search.results)
          .to include(
                'study_id' => study2.id,
                'study_name' => study2.name,
                'text' =>
                "TestCenter2TestPatient2##{visit2.visit_number} - OTHER_2",
                'result_id' => required_series22.id,
                'result_type' => 'RequiredSeries'
              )
      end
    end

    describe 'filtering models' do
      let!(:search) do
        RecordSearch.new(
          user: user,
          query: 'Test',
          models: %w[Study]
        )
      end

      it 'returns matched records' do
        expect(search.results)
          .to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => 'TestStudy1',
            'result_id' => study1.id,
            'result_type' => 'Study'
          )
        expect(search.results)
          .not_to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => "TestCenter1 - #{center1.name}",
            'result_id' => center1.id,
            'result_type' => 'Center'
          )
        expect(search.results)
          .not_to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => 'TestCenter1TestPatient1',
            'result_id' => patient1.id,
            'result_type' => 'Patient'
          )
        expect(search.results)
          .not_to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => "TestCenter1TestPatient1##{visit1.visit_number}",
            'result_id' => visit1.id,
            'result_type' => 'Visit'
          )
        expect(search.results)
          .not_to include(
                'study_id' => study1.id,
                'study_name' => study1.name,
                'text' =>
                "TestCenter1TestPatient1##{visit1.visit_number} - SPECT_1",
                'result_id' => required_series11.id,
                'result_type' => 'RequiredSeries'
              )
        expect(search.results)
          .not_to include(
                'study_id' => study1.id,
                'study_name' => study1.name,
                'text' =>
                "TestCenter1TestPatient1##{visit1.visit_number} - SPECT_2",
                'result_id' => required_series12.id,
                'result_type' => 'RequiredSeries'
              )
        expect(search.results)
          .to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => 'TestStudy2',
            'result_id' => study2.id,
            'result_type' => 'Study'
          )
        expect(search.results)
          .not_to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => "TestCenter2 - #{center2.name}",
            'result_id' => center2.id,
            'result_type' => 'Center'
          )
        expect(search.results)
          .not_to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => 'TestCenter2TestPatient2',
            'result_id' => patient2.id,
            'result_type' => 'Patient'
          )
        expect(search.results)
          .not_to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => "TestCenter2TestPatient2##{visit2.visit_number}",
            'result_id' => visit2.id,
            'result_type' => 'Visit'
          )
        expect(search.results)
          .not_to include(
                'study_id' => study2.id,
                'study_name' => study2.name,
                'text' =>
                "TestCenter2TestPatient2##{visit2.visit_number} - OTHER_1",
                'result_id' => required_series21.id,
                'result_type' => 'RequiredSeries'
              )
        expect(search.results)
          .not_to include(
                'study_id' => study2.id,
                'study_name' => study2.name,
                'text' =>
                "TestCenter2TestPatient2##{visit2.visit_number} - OTHER_2",
                'result_id' => required_series22.id,
                'result_type' => 'RequiredSeries'
              )
      end
    end

    describe 'filtering by study' do
      let!(:search) do
        RecordSearch.new(
          user: user,
          query: 'Test',
          study_id: study1.id
        )
      end

      it 'does not return anything from study 2' do
        expect(search.results)
          .to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => 'TestStudy1',
            'result_id' => study1.id,
            'result_type' => 'Study'
          )
        expect(search.results)
          .to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => "TestCenter1 - #{center1.name}",
            'result_id' => center1.id,
            'result_type' => 'Center'
          )
        expect(search.results)
          .to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => 'TestCenter1TestPatient1',
            'result_id' => patient1.id,
            'result_type' => 'Patient'
          )
        expect(search.results)
          .to include(
            'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => "TestCenter1TestPatient1##{visit1.visit_number}",
            'result_id' => visit1.id,
            'result_type' => 'Visit'
          )
        expect(search.results)
          .to include(
                    'study_id' => study1.id,
                    'study_name' => study1.name,
                    'text' =>
                    "TestCenter1TestPatient1##{visit1.visit_number} - SPECT_1",
                    'result_id' => required_series11.id,
                    'result_type' => 'RequiredSeries'
                  )
        expect(search.results)
          .to include(
                    'study_id' => study1.id,
                    'study_name' => study1.name,
                    'text' =>
                    "TestCenter1TestPatient1##{visit1.visit_number} - SPECT_2",
                    'result_id' => required_series12.id,
                    'result_type' => 'RequiredSeries'
                  )
        expect(search.results)
          .not_to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => 'TestStudy2',
            'result_id' => study2.id,
            'result_type' => 'Study'
          )
        expect(search.results)
          .not_to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => "TestCenter2 - #{center2.name}",
            'result_id' => center2.id,
            'result_type' => 'Center'
          )
        expect(search.results)
          .not_to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => 'TestCenter2TestPatient2',
            'result_id' => patient2.id,
            'result_type' => 'Patient'
          )
        expect(search.results)
          .not_to include(
            'study_id' => study2.id,
            'study_name' => study2.name,
            'text' => "TestCenter2TestPatient2##{visit2.visit_number}",
            'result_id' => visit2.id,
            'result_type' => 'Visit'
          )
        expect(search.results)
          .not_to include(
                    'study_id' => study2.id,
                    'study_name' => study2.name,
                    'text' =>
                    "TestCenter2TestPatient2##{visit2.visit_number} - OTHER_1",
                    'result_id' => required_series21.id,
                    'result_type' => 'RequiredSeries'
                  )
        expect(search.results)
          .not_to include(
                    'study_id' => study2.id,
                    'study_name' => study2.name,
                    'text' =>
                    "TestCenter2TestPatient2##{visit2.visit_number} - OTHER_2",
                    'result_id' => required_series22.id,
                    'result_type' => 'RequiredSeries'
                  )
      end
    end
  end
end
