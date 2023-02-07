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

  describe '::find_record' do
    let!(:comment) { create(:active_admin_comment) }

    it 'finds `ActiveAdminComment`' do
      expect(RecordSearch.find_record("Comment_#{comment.id}")).to eq comment
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
    let!(:study1_result) do
      {
        'study_id' => study1.id,
        'study_name' => study1.name,
        'text' => 'TestStudy1',
        'result_id' => study1.id.to_s,
        'result_type' => 'Study'
      }
    end

    let!(:center1) { create(:center, code: 'TestCenter1', study: study1) }
    let!(:center1_result) do
      {
        'study_id' => study1.id,
        'study_name' => study1.name,
        'text' => "TestCenter1 - #{center1.name}",
        'result_id' => center1.id.to_s,
        'result_type' => 'Center'
      }
    end

    let!(:patient1) { create(:patient, subject_id: 'TestPatient1', center: center1) }
    let!(:patient1_result) do
      {
        'study_id' => study1.id,
        'study_name' => study1.name,
        'text' => 'TestCenter1TestPatient1',
        'result_id' => patient1.id.to_s,
        'result_type' => 'Patient'
      }
    end

    let!(:visit1) { create(:visit, visit_type: 'baseline', visit_number: 2, patient: patient1) }
    let!(:visit1_result) do
     {
'study_id' => study1.id,
            'study_name' => study1.name,
            'text' => "TestCenter1TestPatient1##{visit1.visit_number}",
            'result_id' => visit1.id.to_s,
            'result_type' => 'Visit'
     }
    end


    let!(:required_series11) { visit1.required_series.where(name: 'SPECT_1').first }
    let!(:rs11_result) do
      {
        'study_id' => study1.id,
        'study_name' => study1.name,
        'text' =>
        "TestCenter1TestPatient1##{visit1.visit_number} - SPECT_1",
        'result_id' => required_series11.id.to_s,
        'result_type' => 'RequiredSeries'
      }
    end

    let!(:required_series12) { visit1.required_series.where(name: 'SPECT_2').first }
    let!(:rs12_result) do
      {
        'study_id' => study1.id,
        'study_name' => study1.name,
        'text' =>
        "TestCenter1TestPatient1##{visit1.visit_number} - SPECT_2",
        'result_id' => required_series12.id.to_s,
        'result_type' => 'RequiredSeries'
      }
    end

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
    let!(:study2_result) do
      {
        'study_id' => study2.id,
        'study_name' => study2.name,
        'text' => 'TestStudy2',
        'result_id' => study2.id.to_s,
        'result_type' => 'Study'
      }
    end


    let!(:center2) { create(:center, code: 'TestCenter2', study: study2) }
    let!(:center2_result) do
      {
        'study_id' => study2.id,
        'study_name' => study2.name,
        'text' => "TestCenter2 - #{center2.name}",
        'result_id' => center2.id.to_s,
        'result_type' => 'Center'
      }
    end

    let!(:patient2) { create(:patient, subject_id: 'TestPatient2', center: center2) }
    let!(:patient2_result) do
      {
        'study_id' => study2.id,
        'study_name' => study2.name,
        'text' => 'TestCenter2TestPatient2',
        'result_id' => patient2.id.to_s,
        'result_type' => 'Patient'
      }
    end

    let!(:visit2) { create(:visit, visit_type: 'baseline', visit_number: 2, patient: patient2) }
    let!(:visit2_result) do
      {
        'study_id' => study2.id,
        'study_name' => study2.name,
        'text' => "TestCenter2TestPatient2##{visit2.visit_number}",
        'result_id' => visit2.id.to_s,
        'result_type' => 'Visit'
      }
    end

    let!(:required_series21) { visit2.required_series.where(name: 'OTHER_1').first }
    let!(:rs21_result) do
      {
        'study_id' => study2.id,
        'study_name' => study2.name,
        'text' =>
        "TestCenter2TestPatient2##{visit2.visit_number} - OTHER_1",
        'result_id' => required_series21.id.to_s,
        'result_type' => 'RequiredSeries'
      }
    end

    let!(:required_series22) { visit2.required_series.where(name: 'OTHER_2').first }
    let!(:rs22_result) do
      {
        'study_id' => study2.id,
        'study_name' => study2.name,
        'text' =>
        "TestCenter2TestPatient2##{visit2.visit_number} - OTHER_2",
        'result_id' => required_series22.id.to_s,
        'result_type' => 'RequiredSeries'
      }
    end

    let!(:user) { create(:user, is_root_user: true) }

    let!(:form_definition) { create(:form_definition, name: "Test Form") }
    let!(:form_answer) { create(:form_answer, form_definition: form_definition) }
    let!(:form_answer_result) do
      {
        'study_id' => nil,
        'study_name' => nil,
        'text' => "Test Form",
        'result_id' => form_answer.id.to_s,
        'result_type' => 'FormAnswer'
      }
    end

    let!(:active_admin_comment) { create(:active_admin_comment, resource: visit1, author: user) }
    let!(:active_admin_comment_result) do
      {
        'study_id' => nil,
        'study_name' => nil,
        'text' => "Visit Comment by #{user.name}",
        'result_id' => active_admin_comment.id.to_s,
        'result_type' => 'Comment'
      }
    end


    describe 'filtering for comments' do
      let!(:search) do
        RecordSearch.new(
          user: user,
          query: 'Comment'
        )
      end

      it 'returns matched records' do
        expect(search.results).to include(active_admin_comment_result)
      end
    end

    describe 'filtering for form answers' do
      let!(:search) do
        RecordSearch.new(
          user: user,
          query: 'Form'
        )
      end

      it 'returns matched records' do
        expect(search.results).to include(form_answer_result)
      end
    end

    describe 'not filtering models' do
      let!(:search) do
        RecordSearch.new(
          user: user,
          query: 'Test'
        )
      end

      it 'returns matched records' do
        expect(search.results).to include(study1_result)
        expect(search.results).to include(center1_result)
        expect(search.results).to include(patient1_result)
        expect(search.results).to include(visit1_result)
        expect(search.results).to include(rs11_result)
        expect(search.results).to include(rs12_result)

        expect(search.results).to include(study2_result)
        expect(search.results).to include(center2_result)
        expect(search.results).to include(patient2_result)
        expect(search.results).to include(visit2_result)
        expect(search.results).to include(rs21_result)
        expect(search.results).to include(rs22_result)

        expect(search.results).to include(form_answer_result)
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
        expect(search.results).to include(study1_result)
        expect(search.results).not_to include(center1_result)
        expect(search.results).not_to include(patient1_result)
        expect(search.results).not_to include(visit1_result)
        expect(search.results).not_to include(rs11_result)
        expect(search.results).not_to include(rs12_result)

        expect(search.results).to include(study2_result)
        expect(search.results).not_to include(center2_result)
        expect(search.results).not_to include(patient2_result)
        expect(search.results).not_to include(visit2_result)
        expect(search.results).not_to include(rs21_result)
        expect(search.results).not_to include(rs22_result)

        expect(search.results).not_to include(form_answer_result)
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
        expect(search.results).to include(study1_result)
        expect(search.results).to include(center1_result)
        expect(search.results).to include(patient1_result)
        expect(search.results).to include(visit1_result)
        expect(search.results).to include(rs11_result)
        expect(search.results).to include(rs12_result)

        expect(search.results).not_to include(study2_result)
        expect(search.results).not_to include(center2_result)
        expect(search.results).not_to include(patient2_result)
        expect(search.results).not_to include(visit2_result)
        expect(search.results).not_to include(rs21_result)
        expect(search.results).not_to include(rs22_result)

        expect(search.results).to include(form_answer_result)
      end
    end
  end
end
