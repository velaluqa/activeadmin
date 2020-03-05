RSpec.describe Study::ConsolidateStudyConfiguration do
  let!(:user) { create(:user) }
  let(:dry_run) { false }
  let(:call_operation) do
    Study::ConsolidateStudyConfiguration.call(
      study_id: study.id,
      version: :locked,
      dry_run: dry_run
    )
  end
  let(:tracked_changes) { call_operation[:changes] }

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
      result = call_operation

      expect(RequiredSeries.all).to be_empty
      expect(result[:changes][:added]).to be_empty
      expect(result[:changes][:removed]).to be_empty
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

      before(:each) do
        visit_followup.mqc_state = 2
        visit_followup.mqc_results = { "modality" => true }
        visit_followup.mqc_user = user
        visit_followup.mqc_comment = "This is a comment"
        visit_followup.save!
      end

      it 'unsets visit type attribute' do
        expect(Visit.count).to eq(2)
        expect(Visit.all.map(&:visit_type)).to include("baseline", "followup")
        call_operation
        expect(Visit.count).to eq(2)
        expect(Visit.all.map(&:visit_type)).not_to include("baseline", "followup")
      end

      it 'removes existing required series' do
        expect(RequiredSeries.all.map(&:name)).to include("SPECT")
        call_operation
        expect(RequiredSeries.all.map(&:name)).not_to include("SPECT")
      end

      it 'resets mQC results' do
        visit_followup.reload
        expect(visit_followup.mqc_state_sym).to eq(:passed)

        call_operation

        visit_followup.reload
        expect(visit_followup.mqc_state_sym).to eq(:pending)
      end

      it 'tracks changes' do
        expected_messages = [
          {
            visit_id: visit_baseline.id,
            message: "Unsetting visit type 'baseline'"
          },
          {
            visit_id: visit_followup.id,
            message: "Unsetting visit type 'followup'"
          },
          {
            visit_id: visit_followup.id,
            message: "Resetting mQC due to changed mQC specification"
          },
          {
            visit_id: visit_followup.id,
            message: "Removing obsolete required series 'SPECT'"
          },
        ]
        expect(tracked_changes[:removed]).to include(*expected_messages)
      end

      describe 'dry-run' do
        let(:dry_run) { true }

        it 'leaves visit type attributes' do
          expect(Visit.count).to eq(2)
          expect(Visit.all.map(&:visit_type)).to include("baseline", "followup")
          call_operation
          expect(Visit.count).to eq(2)
          expect(Visit.all.map(&:visit_type)).to include("baseline", "followup")
        end

        it 'removes existing required series' do
          expect(RequiredSeries.all.map(&:name)).to include("SPECT")
          call_operation
          expect(RequiredSeries.all.map(&:name)).to include("SPECT")
        end

        it 'tracks changes' do
          expected_messages = [
            {
              visit_id: visit_baseline.id,
              message: "Unsetting visit type 'baseline'"
            },
            {
              visit_id: visit_followup.id,
              message: "Unsetting visit type 'followup'"
            },
            {
              visit_id: visit_followup.id,
              message: "Resetting mQC due to changed mQC specification"
            },
            {
              visit_id: visit_followup.id,
              message: "Removing obsolete required series 'SPECT'"
            },
          ]
          expect(tracked_changes[:removed]).to include(*expected_messages)
        end
      end
    end

    describe 'changing '

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
        visit_baseline.update_attributes(visit_type: 'baseline')
        visit_followup.update_attributes(visit_type: 'followup')
      end

      it 'adds the required series' do
        expect(RequiredSeries.all.map(&:name)).not_to include("SPECT")
        call_operation
        expect(RequiredSeries.all.map(&:name)).to include("SPECT")
      end

      it 'tracks changes' do
        expected_messages = [
          {
            visit_id: visit_followup.id,
            message: "Creating required series 'SPECT'"
          }
        ]
        expect(tracked_changes[:added]).to include(*expected_messages)
      end

      describe 'dry-run' do
        let(:dry_run) { true }

        it 'does nothing' do
          expect(RequiredSeries.all.map(&:name)).not_to include("SPECT")
          call_operation
          expect(RequiredSeries.all.map(&:name)).not_to include("SPECT")
        end

        it 'tracks changes' do
          expected_messages = [
            {
              visit_id: visit_followup.id,
              message: "Creating required series 'SPECT'"
            }
          ]
          expect(tracked_changes[:added]).to include(*expected_messages)
        end
      end
    end


    describe 'removing a required series' do
      let!(:required_series) { create(:required_series, visit: visit_followup, name: 'SPECT') }

      it 'removes the required series' do
        expect(RequiredSeries.all.map(&:name)).to include("SPECT")
        call_operation
        expect(RequiredSeries.all.map(&:name)).not_to include("SPECT")
      end

      it 'tracks changes' do
        expected_message = include(
          visit_id: visit_followup.id,
          message: "Removing obsolete required series 'SPECT'"
        )
        expect(tracked_changes[:removed]).to include(expected_message)
      end

      describe 'dry-run' do
        let(:dry_run) { true }

        it 'does nothing' do
          expect(RequiredSeries.all.map(&:name)).to include("SPECT")
          call_operation
          expect(RequiredSeries.all.map(&:name)).to include("SPECT")
        end

        it 'tracks changes' do
          expected_message = include(
            visit_id: visit_followup.id,
            message: "Removing obsolete required series 'SPECT'"
          )
          expect(tracked_changes[:removed]).to include(expected_message)
        end
      end
    end

    describe 'changing a mqc spec for visit with existing results' do
      before(:each) do
        study.unlock_configuration!
        study.update_configuration!(<<~CONFIG)
          visit_types:
            baseline:
              required_series: {}
            followup:
              required_series:
                SPECT1:
                  tqc: []
                SPECT2:
                  tqc: []
              mqc:
              - id: modality
                label: 'Correct?'
                type: bool
          image_series_properties: []
        CONFIG
        study.lock_configuration!
      end

      before(:each) do
        visit_followup.set_mqc_result(
          { "modality" => true },
          user,
          "This is a comment!"
        )
      end

      before(:each) do
        study.unlock_configuration!
        study.update_configuration!(<<~CONFIG)
          visit_types:
            baseline:
              required_series: {}
            followup:
              required_series:
                SPECT1:
                  tqc: []
                SPECT2:
                  tqc: []
              mqc:
              - id: confidence
                label: 'Correct?'
                type: bool
          image_series_properties: []
        CONFIG
        study.lock_configuration!
      end

      it 'resets the mQC results' do
        visit_followup.reload
        expect(visit_followup.mqc_state_sym).to eq(:passed)

        call_operation

        visit_followup.reload
        expect(visit_followup.mqc_state_sym).to eq(:pending)
      end

      it 'tracks changes' do
        expected_message = include(
          visit_id: visit_followup.id,
          message: "Resetting mQC due to changed mQC specification"
        )
        expect(tracked_changes[:removed]).to include(expected_message)
      end

      describe 'dry-run' do
        let(:dry_run) { true }

        it 'does nothing' do
          visit_followup.reload
          expect(visit_followup.mqc_state_sym).to eq(:passed)

          call_operation

          visit_followup.reload
          expect(visit_followup.mqc_state_sym).to eq(:passed)
        end

        it 'tracks changes' do
          expected_message = include(
            visit_id: visit_followup.id,
            message: "Resetting mQC due to changed mQC specification"
          )
          expect(tracked_changes[:removed]).to include(expected_message)
        end
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
                  - id: something_else
                    label: 'Correct?'
                    type: bool
          image_series_properties: []
        CONFIG
        study.lock_configuration!
      end

      it 'resets the tQC results' do
        required_series2.reload
        expect(required_series2.tqc_state).to eq('passed')

        call_operation

        required_series2.reload
        expect(required_series2.tqc_state).to eq('pending')
      end

      it 'tracks changes' do
        expected_message = include(
          visit_id: visit_followup.id,
          message: "Resetting tQC results for required series 'SPECT2'"
        )
        expect(tracked_changes[:removed]).to include(expected_message)
      end

      describe 'dry-run' do
        let(:dry_run) { true }

        it 'does nothing' do
          required_series2.reload
          expect(required_series2.tqc_state).to eq('passed')

          call_operation

          required_series2.reload
          expect(required_series2.tqc_state).to eq('passed')
        end

        it 'tracks changes' do
          expected_message = include(
            visit_id: visit_followup.id,
            message: "Resetting tQC results for required series 'SPECT2'"
          )
          expect(tracked_changes[:removed]).to include(expected_message)
        end
      end
    end
  end
end
