require 'record_search'

describe RecordSearch do
  describe '#new' do
    let!(:user) { create(:user) }
    let!(:search) do
      RecordSearch.new(
        user: user,
        query: 'foo',
        models: %w(Notification BackgroundJob Study Center Patient Visit ImageSeries Image)
      )
    end

    it 'initializes user, query and only allowed models' do
      expect(search.user).to eq user
      expect(search.query).to eq 'foo'
      expect(search.models).to eq %w(BackgroundJob Study Center Patient Visit ImageSeries Image)
    end
  end

  describe '#results' do
    let!(:study1) { create(:study, name: 'TestStudy1') }
    let!(:center1) { create(:center, code: 'TestCenter1', study: study1) }
    let!(:patient1) { create(:patient, subject_id: 'TestPatient1', center: center1) }
    let!(:visit1) { create(:visit, visit_number: 2, patient: patient1) }
    let!(:study2) { create(:study, name: 'TestStudy2') }
    let!(:center2) { create(:center, code: 'TestCenter2', study: study2) }
    let!(:patient2) { create(:patient, subject_id: 'TestPatient2', center: center2) }
    let!(:visit2) { create(:visit, visit_number: 2, patient: patient2) }
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
                'study_id' => study1.id.to_s,
                'study_name' => study1.name,
                'text' => 'TestStudy1',
                'result_id' => study1.id.to_s,
                'result_type' => 'Study'
              )
        expect(search.results)
          .to include(
                'study_id' => study1.id.to_s,
                'study_name' => study1.name,
                'text' => "TestCenter1 - #{center1.name}",
                'result_id' => center1.id.to_s,
                'result_type' => 'Center'
              )
        expect(search.results)
          .to include(
                'study_id' => study1.id.to_s,
                'study_name' => study1.name,
                'text' => 'TestCenter1TestPatient1',
                'result_id' => patient1.id.to_s,
                'result_type' => 'Patient'
              )
        expect(search.results)
          .to include(
                'study_id' =>  study1.id.to_s,
                'study_name' =>  study1.name,
                'text'=> "TestCenter1TestPatient1##{visit1.visit_number}",
                'result_id' => visit1.id.to_s,
                'result_type' => 'Visit'
              )
        expect(search.results)
          .to include(
                'study_id' => study2.id.to_s,
                'study_name' => study2.name,
                'text' => 'TestStudy2',
                'result_id' => study2.id.to_s,
                'result_type' => 'Study'
              )
        expect(search.results)
          .to include(
                'study_id' => study2.id.to_s,
                'study_name' => study2.name,
                'text' => "TestCenter2 - #{center2.name}",
                'result_id' => center2.id.to_s,
                'result_type' => 'Center'
              )
        expect(search.results)
          .to include(
                'study_id' => study2.id.to_s,
                'study_name' => study2.name,
                'text' => 'TestCenter2TestPatient2',
                'result_id' => patient2.id.to_s,
                'result_type' => 'Patient'
              )
        expect(search.results)
          .to include(
                'study_id' =>  study2.id.to_s,
                'study_name' =>  study2.name,
                'text'=> "TestCenter2TestPatient2##{visit2.visit_number}",
                'result_id' => visit2.id.to_s,
                'result_type' => 'Visit'
              )
      end
    end

    describe 'filtering models' do
      let!(:search) do
        RecordSearch.new(
          user: user,
          query: 'Test',
          models: %w(Study)
        )
      end

      it 'returns matched records' do
        expect(search.results)
          .to include(
                'study_id' => study1.id.to_s,
                'study_name' => study1.name,
                'text' => 'TestStudy1',
                'result_id' => study1.id.to_s,
                'result_type' => 'Study'
              )
        expect(search.results)
          .not_to include(
                    'study_id' => study1.id.to_s,
                    'study_name' => study1.name,
                    'text' => "TestCenter1 - #{center1.name}",
                    'result_id' => center1.id.to_s,
                    'result_type' => 'Center'
                  )
        expect(search.results)
          .not_to include(
                    'study_id' => study1.id.to_s,
                    'study_name' => study1.name,
                    'text' => 'TestCenter1TestPatient1',
                    'result_id' => patient1.id.to_s,
                    'result_type' => 'Patient'
                  )
        expect(search.results)
          .not_to include(
                    'study_id' => study1.id.to_s,
                    'study_name' => study1.name,
                    'text' => "TestCenter1TestPatient1##{visit1.visit_number}",
                    'result_id' => visit1.id.to_s,
                    'result_type' => 'Visit'
                  )
        expect(search.results)
          .to include(
                'study_id' => study2.id.to_s,
                'study_name' => study2.name,
                'text' => 'TestStudy2',
                'result_id' => study2.id.to_s,
                'result_type' => 'Study'
              )
        expect(search.results)
          .not_to include(
                    'study_id' => study2.id.to_s,
                    'study_name' => study2.name,
                    'text' => "TestCenter2 - #{center2.name}",
                    'result_id' => center2.id.to_s,
                    'result_type' => 'Center'
                  )
        expect(search.results)
          .not_to include(
                    'study_id' => study2.id.to_s,
                    'study_name' => study2.name,
                    'text' => 'TestCenter2TestPatient2',
                    'result_id' => patient2.id.to_s,
                    'result_type' => 'Patient'
                  )
        expect(search.results)
          .not_to include(
                    'study_id' => study2.id.to_s,
                    'study_name' => study2.name,
                    'text' => "TestCenter2TestPatient2##{visit2.visit_number}",
                    'result_id' => visit2.id.to_s,
                    'result_type' => 'Visit'
                  )
      end
    end

    describe 'filtering models' do
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
                'study_id' => study1.id.to_s,
                'study_name' => study1.name,
                'text' => 'TestStudy1',
                'result_id' => study1.id.to_s,
                'result_type' => 'Study'
              )
        expect(search.results)
          .to include(
                    'study_id' => study1.id.to_s,
                    'study_name' => study1.name,
                    'text' => "TestCenter1 - #{center1.name}",
                    'result_id' => center1.id.to_s,
                    'result_type' => 'Center'
                  )
        expect(search.results)
          .to include(
                    'study_id' => study1.id.to_s,
                    'study_name' => study1.name,
                    'text' => 'TestCenter1TestPatient1',
                    'result_id' => patient1.id.to_s,
                    'result_type' => 'Patient'
                  )
        expect(search.results)
          .to include(
                    'study_id' => study1.id.to_s,
                    'study_name' => study1.name,
                    'text' => "TestCenter1TestPatient1##{visit1.visit_number}",
                    'result_id' => visit1.id.to_s,
                    'result_type' => 'Visit'
                  )
        expect(search.results)
          .not_to include(
                'study_id' => study2.id.to_s,
                'study_name' => study2.name,
                'text' => 'TestStudy2',
                'result_id' => study2.id.to_s,
                'result_type' => 'Study'
              )
        expect(search.results)
          .not_to include(
                    'study_id' => study2.id.to_s,
                    'study_name' => study2.name,
                    'text' => "TestCenter2 - #{center2.name}",
                    'result_id' => center2.id.to_s,
                    'result_type' => 'Center'
                  )
        expect(search.results)
          .not_to include(
                    'study_id' => study2.id.to_s,
                    'study_name' => study2.name,
                    'text' => 'TestCenter2TestPatient2',
                    'result_id' => patient2.id.to_s,
                    'result_type' => 'Patient'
                  )
        expect(search.results)
          .not_to include(
                    'study_id' => study2.id.to_s,
                    'study_name' => study2.name,
                    'text' => "TestCenter2TestPatient2##{visit2.visit_number}",
                    'result_id' => visit2.id.to_s,
                    'result_type' => 'Visit'
                  )
      end
    end
  end
end
