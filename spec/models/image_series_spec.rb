RSpec.describe ImageSeries do
  describe '#assigned_required_series' do
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }
    let!(:visit) { create(:visit, patient: patient) }
    let!(:series1) { create(:image_series, visit: visit, patient: patient) }
    let!(:required_series1) { create(:required_series, visit: visit, name: 'SPECT_1') }
    let!(:required_series2) { create(:required_series, visit: visit, name: 'SPECT_2') }

    before(:each) do
      required_series1.assign_image_series!(series1)
      required_series2.assign_image_series!(series1)
    end

    it 'returns assigned required series' do
      expect(series1.assigned_required_series).to include(required_series1)
      expect(series1.assigned_required_series).to include(required_series2)
    end
  end

  describe '#state=' do
    context 'after save' do
      let!(:image_series) { create(:image_series) }

      before(:each) do
        image_series.state = :imported
        image_series.save
      end

      let!(:version) { Version.last }

      it 'has the new state' do
        image_series = ImageSeries.last
        expect(image_series.state).to eq(1)
        expect(image_series.state_sym).to eq(:imported)
      end

      it 'saved the correct version object_changes for state' do
        expect(version.object_changes.dig2('state', 1)).to eq(1)
      end
    end
  end

  describe '#to_json' do
    let(:image_series) { create(:image_series) }
    it 'gathers the `state` symbol instead of the `state` index' do
      expect(image_series.to_json).to include('"state":"importing"')
    end
  end

  describe 'scope ::searchable' do
    it 'selects search fields' do
      series = create(:image_series, name: 'FooSeries', series_number: '123')
      expect(ImageSeries.searchable.as_json)
        .to eq [{
          'id' => nil,
          'study_id' => series.patient.center.study_id,
          'study_name' => series.patient.center.study.name,
          'text' => 'FooSeries (123)',
          'result_id' => series.id,
          'result_type' => 'ImageSeries'
        }]
    end
  end

  describe 'image storage' do
    before(:each) do
      @study = create(:study, id: 1)
      @center = create(:center, id: 1, study: @study)
      @patient = create(:patient, id: 1, center: @center)
      @patient2 = create(:patient, id: 2, center: @center)
      @visit = create(:visit, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/1'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/2/__unassigned'))
    end

    it 'handles create' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
      create(:image_series, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
    end

    it 'handles update of patient_id' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
      image_series = create(:image_series, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
      image_series.patient_id = 2
      image_series.save
      expect(File).to exist(ERICA.image_storage_path.join('1/1/2/__unassigned/1'))
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
    end

    it 'handles update of visit_id' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
      image_series = create(:image_series, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
      image_series.visit_id = 1
      image_series.save
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/1/1'))
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
    end

    it 'handles destroy' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
      image_series = create(:image_series, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
      image_series.destroy
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
    end
  end

  describe 'scope #by_study_ids' do
    before :each do
      @study1     = create(:study)
      @center11   = create(:center, study: @study1)

      @patient111 = create(:patient, center: @center11)
      @visit1111  = create(:visit, patient: @patient111)
      @image_series11111 = create(:image_series, visit: @visit1111)

      @center12   = create(:center, study: @study1)
      @patient121 = create(:patient, center: @center12)
      @visit1211  = create(:visit, patient: @patient121)
      @image_series12111 = create(:image_series, visit: @visit1211)

      @study2     = create(:study)
      @center21   = create(:center, study: @study2)

      @patient211 = create(:patient, center: @center21)
      @visit2111  = create(:visit, patient: @patient211)
      @image_series21111 = create(:image_series, visit: @visit2111)

      @center22   = create(:center, study: @study2)
      @patient221 = create(:patient, center: @center22)
      @visit2211  = create(:visit, patient: @patient221)
      @image_series22111 = create(:image_series, visit: @visit2211)

      @study3     = create(:study)
      @center31   = create(:center, study: @study3)

      @patient311 = create(:patient, center: @center31)
      @visit3111  = create(:visit, patient: @patient311)
      @image_series31111 = create(:image_series, visit: @visit3111)

      @center32   = create(:center, study: @study3)
      @patient321 = create(:patient, center: @center32)
      @visit3211  = create(:visit, patient: @patient321)
      @image_series32111 = create(:image_series, visit: @visit3211)
    end

    it 'returns the matched image_series by a single study' do
      expect(ImageSeries.by_study_ids(@study1.id))
        .to match_array [@image_series11111, @image_series12111]
    end

    it 'returns the matched image_series by multiple studies' do
      expect(ImageSeries.by_study_ids(@study1.id, @study3.id))
        .to match_array [
          @image_series11111, @image_series12111,
          @image_series31111, @image_series32111
        ]
      expect(ImageSeries.by_study_ids([@study1.id, @study3.id]))
        .to match_array [
          @image_series11111, @image_series12111,
          @image_series31111, @image_series32111
        ]
    end
  end

  describe 'versioning' do
    describe 'create' do
      before(:each) do
        @image_series = create(:image_series)
        @study_id = @image_series.study.id
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'ImageSeries').last
        expect(version.study_id).to eq @study_id
      end
    end
    describe 'update' do
      before(:each) do
        @image_series = create(:image_series)
        @study_id = @image_series.study.id
        @image_series.name = 'New Name'
        @image_series.save!
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'ImageSeries').last
        expect(version.event).to eq 'update'
        expect(version.study_id).to eq @study_id
      end
    end
    describe 'destroy' do
      before(:each) do
        @image_series = create(:image_series)
        @study_id = @image_series.study.id
        @image_series.destroy
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'ImageSeries').last
        expect(version.event).to eq 'destroy'
        expect(version.study_id).to eq @study_id
      end
    end
  end
end
