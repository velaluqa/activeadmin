RSpec.describe Study::ConsolidateStudyConfiguration do
  let!(:user) { create(:user) }

  describe 'study is not locked ' do
    let!(:study) { create(:study, configuration: <<~CONFIG) }
      visit_types:
        baseline:
          required_series: {}
        followup:
          required_series:
            SPECT:
              tqc: []
      image_series_properties: []
    CONFIG

    it 'does not do anything for locked version' do
      Study::ConsolidateStudyConfiguration.call(
        study_id: study.id,
        version: :locked
      )
      expect(RequiredSeries.all).to be_empty
    end
  end

  describe 'study is locked' do
    let!(:study) { create(:study, :locked, configuration: <<~CONFIG) }
      visit_types: {}
      image_series_properties: []
    CONFIG
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }
    let!(:image_series) { create(:image_series, patient: patient) }
    let!(:visit_baseline) { create(:visit, patient: patient, visit_type: 'baseline') }
    let!(:visit_followup) { create(:visit, patient: patient, visit_type: 'followup') }

    describe 'removing visit types' do
      let!(:required_series) { create(:required_series, visit: visit_followup, name: 'SPECT') }

      it 'unsets visit type attribute' do
        expect(Visit.count).to eq(2)
        expect(Visit.all.map(&:visit_type)).to include("baseline", "followup")
        Study::ConsolidateStudyConfiguration.call(
          study_id: study.id,
          version: :locked
        )
        expect(Visit.count).to eq(2)
        expect(Visit.all.map(&:visit_type)).not_to include("baseline", "followup")
      end

      it 'removes existing required series' do
        expect(RequiredSeries.all.map(&:name)).to include("SPECT")
        Study::ConsolidateStudyConfiguration.call(
          study_id: study.id,
          version: :locked
        )
        expect(RequiredSeries.all.map(&:name)).not_to include("SPECT")
      end
    end

    describe 'adding a required series' do
      before(:each) do
        study.unlock_configuration!
        study.update_configuration!(<<~CONFIG)
          visit_types:
            baseline:
              required_series: {}
            followup:
              required_series:
                SPECT:
                  tqc: []
          image_series_properties: []
        CONFIG
        study.lock_configuration!
      end

      it 'adds the required series' do
        expect(RequiredSeries.all.map(&:name)).not_to include("SPECT")
        Study::ConsolidateStudyConfiguration.call(
          study_id: study.id,
          version: :locked
        )
        expect(RequiredSeries.all.map(&:name)).to include("SPECT")
      end
    end

    describe 'removing a required series' do
      let!(:required_series) { create(:required_series, visit: visit_followup, name: 'SPECT') }

      it 'removes the required series' do
        expect(RequiredSeries.all.map(&:name)).to include("SPECT")
        Study::ConsolidateStudyConfiguration.call(
          study_id: study.id,
          version: :locked
        )
        expect(RequiredSeries.all.map(&:name)).not_to include("SPECT")
      end
    end

    describe 'changing a tqc spec for required series with existing results' do
      before(:each) do
        study.unlock_configuration!
        study.update_configuration!(<<~CONFIG)
          visit_types:
            baseline:
              required_series: {}
            followup:
              required_series:
                SPECT1:
                  tqc:
                  - id: modality
                    label: 'Correct?'
                    type: bool
                SPECT2:
                  tqc:
                  - id: modality
                    label: 'Correct?'
                    type: bool
          image_series_properties: []
        CONFIG
        study.lock_configuration!
      end

      let!(:required_series1) { create(:required_series, visit: visit_followup, name: 'SPECT1') }
      let!(:required_series2) { create(:required_series, visit: visit_followup, image_series: image_series, name: 'SPECT2') }

      before(:each) do
        visit_followup.set_tqc_result(
          'SPECT2',
          { "modality" => true },
          user,
          "This is a comment!"
        )
      end

      it 'resets the tQC results' do
        study.unlock_configuration!
        study.update_configuration!(<<~CONFIG)
          visit_types:
            baseline:
              required_series: {}
            followup:
              required_series:
                SPECT1:
                  tqc:
                  - id: modality
                    label: 'Correct?'
                    type: bool
                SPECT2:
                  tqc:
                  - id: modality
                    label: 'Correct?'
                    type: bool
                  - id: something_else
                    label: 'Correct?'
                    type: bool
          image_series_properties: []
        CONFIG
        study.lock_configuration!

        required_series2.reload
        expect(required_series2.tqc_state).to eq('passed')

        Study::ConsolidateStudyConfiguration.call(
          study_id: study.id,
          version: :locked
        )
        required_series2.reload
        expect(required_series2.tqc_state).to eq('pending')
      end
    end
  end
end
