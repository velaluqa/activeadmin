describe RequiredSeries do
  describe 'model' do
    it 'has a valid factory' do
      expect(build(:required_series)).to be_valid
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
end
