describe RequiredSeries do
  describe 'model' do
    it 'has a valid factory' do
      expect(build(:required_series)).to be_valid
    end
  end

  describe 'versioning' do
    let!(:required_series) { create(:required_series) }

    it 'saves enum string into object changes' do
      required_series.tqc_state = 'pending'
      required_series.save!
      expect(Version.last.object_changes.dig2('tqc_state', 0)).to be_nil
      expect(Version.last.object_changes.dig2('tqc_state', 1)).to eq('pending')
    end

    it 'saves enum string into `destroy` version' do
      required_series.tqc_state = 'issues'
      required_series.save!
      required_series.destroy
      expect(Version.last.object['tqc_state']).to eq('issues')
    end
  end

  describe '#assign_image_series!' do
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
    let!(:patient) { create(:patient, center: center) }
    let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }
    let!(:series1) { create(:image_series, patient: patient, visit: visit) }
    let!(:series2) { create(:image_series, patient: patient, visit: visit) }
    let!(:spect_1) { RequiredSeries.where(visit: visit, name: 'SPECT_1').first }

    before(:each) do
      spect_1.update_attributes(
        tqc_state: 'passed',
        tqc_results: {},
        tqc_date: Time.now,
        tqc_user_id: create(:user).id
      )
      spect_1.assign_image_series!(series1)
      series1.reload
      series2.reload
    end

    describe 'first assign' do
      it 'sets image series' do
        expect(spect_1.image_series).to eq(series1)
      end
      it 'resets tqc results' do
        expect(spect_1.tqc_state).to eq('pending')
      end
      it 'sets assigned image series state to `required_series_assigned`' do
        expect(series1.state_sym).to eq(:required_series_assigned)
      end
      it 'creates image storage symbolic link for required series' do
        path = ERICA.image_storage_path.join(spect_1.image_storage_path)
        expect(File).to exist(path)
        expect(File).to be_symlink(path)
        expect(File.readlink(path)).to eq(series1.id.to_s)
      end
      it 'schedules image series domoino sync', transactional_spec: true do
        expect(DominoSyncWorker).to have_enqueued_sidekiq_job('ImageSeries', series1.id)
      end
      it 'schedules required series domoino sync', transactional_spec: true do
        expect(DominoSyncWorker).to have_enqueued_sidekiq_job('RequiredSeries', spect_1.id)
      end
    end

    describe 'reassigning' do
      before(:each) do
        spect_1.update_attributes(
          tqc_state: 'passed',
          tqc_results: {},
          tqc_date: Time.now,
          tqc_user_id: create(:user).id
        )
        spect_1.assign_image_series!(series2)
        series1.reload
        series2.reload
      end

      it 'sets image series' do
        expect(spect_1.image_series).to eq(series2)
      end
      it 'resets tqc results' do
        expect(spect_1.tqc_state).to eq('pending')
      end
      it 'sets assigned image series state to `required_series_assigned`' do
        expect(series2.state_sym).to eq(:required_series_assigned)
      end
      it 'sets unassigned image series state to `visit_assigned`' do
        expect(series1.state_sym).to eq(:visit_assigned)
      end
      it 'updates image storage symbolic link for required series' do
        path = ERICA.image_storage_path.join(spect_1.image_storage_path)
        expect(File).to exist(path)
        expect(File).to be_symlink(path)
        expect(File.readlink(path)).to eq(series2.id.to_s)
      end
      it 'schedules image series domoino sync', transactional_spec: true do
        expect(DominoSyncWorker).to have_enqueued_sidekiq_job('ImageSeries', series1.id)
        expect(DominoSyncWorker).to have_enqueued_sidekiq_job('ImageSeries', series2.id)
      end
      it 'schedules required series domoino sync', transactional_spec: true do
        expect(DominoSyncWorker).to have_enqueued_sidekiq_job('RequiredSeries', spect_1.id)
      end
    end
  end

  describe '#unassign_image_series!' do
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
    let!(:patient) { create(:patient, center: center) }
    let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }
    let!(:series1) { create(:image_series, patient: patient, visit: visit) }
    let!(:series2) { create(:image_series, patient: patient, visit: visit) }
    let!(:spect_1) { RequiredSeries.where(visit: visit, name: 'SPECT_1').first }
    let!(:spect_2) { RequiredSeries.where(visit: visit, name: 'SPECT_2').first }

    describe 'for image series assigned once' do
      before(:each) do
        spect_1.update_attributes(
          tqc_state: 'passed',
          tqc_results: {},
          tqc_date: Time.now,
          tqc_user_id: create(:user).id
        )
        spect_1.assign_image_series!(series2)
        spect_1.unassign_image_series!
        series1.reload
        series2.reload
      end

      it 'sets image series to nil' do
        expect(spect_1.image_series).to be_nil
      end
      it 'resets tqc results' do
        expect(spect_1.tqc_state).to be_nil
      end
      it 'sets unassigned image series state to `visit_assigned`' do
        expect(series2.state_sym).to eq(:visit_assigned)
      end
      it 'removes image storage symbolic link for required series' do
        path = ERICA.image_storage_path.join(spect_1.image_storage_path)
        expect(File).not_to exist(path)
      end
      it 'schedules image series domoino sync', transactional_spec: true do
        expect(DominoSyncWorker).to have_enqueued_sidekiq_job('ImageSeries', series2.id)
      end
      it 'schedules required series domoino sync', transactional_spec: true do
        expect(DominoSyncWorker).to have_enqueued_sidekiq_job('RequiredSeries', spect_1.id)
      end
    end

    describe 'for cross-assigned image series' do
      before(:each) do
        spect_1.assign_image_series!(series1)
        spect_2.assign_image_series!(series1)
        spect_1.unassign_image_series!
        series1.reload
      end

      it 'keeps image series state at `required_series_assigned`' do
        expect(series1.state_sym).to eq(:required_series_assigned)
      end
    end
  end

  describe '#domino_document_query' do
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }
    let!(:visit) { create(:visit, patient: patient) }
    let!(:required_series) { create(:required_series, visit: visit, name: 'SPECT_1')}

    it 'returns the correct query' do
      expect(required_series.domino_document_query)
        .to eq(
              'docCode' => 10044,
              'ericaID' => required_series.visit.id,
              'RequiredSeries' => 'SPECT_1'
            )
    end
  end

  describe '#domino_document_properties' do
    let!(:study) { create(:study, configuration: <<CONFIG) }
    visit_types:
      baseline:
        required_series:
          SPECT_1:
            tqc:
              - id: coverage
                label: 'Is the entire region covered?'
                type: bool
              - id: contrast_new
                label: 'Correct contrast phase according to new standards?'
                type: bool
          SPECT_2:
            tqc:
              - id: coverage
                label: 'Is the entire region covered?'
                type: bool
              - id: contrast_new
                label: 'Correct contrast phase according to new standards?'
                type: bool
    image_series_properties: []
CONFIG
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }
    let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }
    let!(:image_series) { create(:image_series, visit: visit) }

    describe 'for required series without assigned image series' do
      let!(:required_series) { visit.required_series.where(name: 'SPECT_1').first }

      it 'returns the correct properties' do
        expect(required_series.domino_document_properties)
          .to include(
                'ericaID' => visit.id,
                'CenterNo' => center.code,
                'PatNo' => patient.domino_patient_no,
                'VisitNo' => visit.visit_number,
                'RequiredSeries' => 'SPECT_1',
                'trash' => 1,
                'ericaASID' => nil,
                'DateImaging' => {
                  'data' => '01-01-0001',
                  'type' => 'datetime'
                },
                'SeriesDescription' => nil,
                'DICOMTagNames' => nil,
                'DICOMValues' => nil,
                'QCdate' => {
                  'data' => '01-01-0001',
                  'type' => 'datetime'
                },
                'QCperson' => nil,
                'QCresult' => nil,
                'QCcomment' => nil,
                'QCCriteriaNames' => nil,
                'QCValues' => nil,
              )
      end
    end
    describe 'for required series with assigned image series' do
      let!(:required_series) { visit.required_series.where(name: 'SPECT_1').first }

      before(:each) do
        required_series.image_series = image_series
        required_series.save!
      end

      it 'returns the correct properties' do
        expect(required_series.domino_document_properties)
          .to include(
                'ericaID' => visit.id,
                'CenterNo' => center.code,
                'PatNo' => patient.domino_patient_no,
                'VisitNo' => visit.visit_number,
                'RequiredSeries' => 'SPECT_1',
                'trash' => 0,
                'ericaASID' => image_series.id,
                'DateImaging' => {
                  'data' => image_series.imaging_date.strftime('%d-%m-%Y'),
                  'type' => 'datetime'
                },
                'SeriesDescription' => image_series.name,
                'QCdate' => {
                  'data' => '01-01-0001',
                  'type' => 'datetime'
                },
                'QCperson' => nil,
                'QCresult' => nil,
                'QCcomment' => nil,
                'QCCriteriaNames' => nil,
                'QCValues' => nil,
              )
      end
    end
    describe 'for required series with results' do
      let!(:user) { create(:user) }
      let!(:required_series) { visit.required_series.where(name: 'SPECT_1').first }

      before(:each) do
        required_series.image_series = image_series
        required_series.update_attributes(
          image_series: image_series,
          tqc_date: DateTime.now,
          tqc_results: {
            'coverage' => true,
            'contrast_new' => false
          },
          tqc_comment: 'Something interesting',
          tqc_state: :passed,
          tqc_user_id: user.id,
        )
        required_series.save!
      end

      it 'returns the correct properties' do
        expect(required_series.domino_document_properties)
          .to include(
                'ericaID' => visit.id,
                'CenterNo' => center.code,
                'PatNo' => patient.domino_patient_no,
                'VisitNo' => visit.visit_number,
                'RequiredSeries' => 'SPECT_1',
                'trash' => 0,
                'ericaASID' => image_series.id,
                'DateImaging' => {
                  'data' => image_series.imaging_date.strftime('%d-%m-%Y'),
                  'type' => 'datetime'
                },
                'SeriesDescription' => image_series.name,
                'QCdate' => {
                  'data' => required_series.tqc_date.strftime('%d-%m-%Y'),
                  'type' => 'datetime'
                },
                'QCperson' => user.name,
                'QCresult' => 'Performed, no issues present',
                'QCcomment' => 'Something interesting',
                'QCCriteriaNames' => <<CRITERIA.strip_heredoc.strip,
                Is the entire region covered?
                Correct contrast phase according to new standards?
CRITERIA
                'QCValues' => "Pass\nFail",
              )
      end
    end
  end
end
