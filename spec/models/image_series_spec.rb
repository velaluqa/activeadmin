RSpec.describe ImageSeries do
  describe 'scope ::searchable' do
    it 'selects search fields' do
      series = create(:image_series, series_number: '123')
      expect(ImageSeries.searchable.as_json)
        .to eq [{
                  'id' => nil,
                  'study_id' => series.patient.center.study_id,
                  'text' => '123',
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
end
