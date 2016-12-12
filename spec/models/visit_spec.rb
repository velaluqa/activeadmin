RSpec.describe Visit do
  describe 'scope ::searchable' do
    it 'selects search fields' do
      center = create(:center, code: 'Foo')
      patient = create(:patient, subject_id: 'Bar', center: center)
      visit = create(:visit, patient: patient)
      expect(Visit.joins(patient: :center).searchable.as_json)
        .to eq [{
                  'id' => nil,
                  'study_id' => visit.patient.center.study_id,
                  'text' => "FooBar##{visit.visit_number}",
                  'result_id' => visit.id,
                  'result_type' => 'Visit'
                }]
    end
  end

  describe 'image storage' do
    before(:each) do
      @study = create(:study, id: 1)
      @center = create(:center, id: 1, study: @study)
      @patient = create(:patient, id: 1, center: @center)
      @patient2 = create(:patient, id: 2, center: @center)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/2/__unassigned'))
    end

    it 'handles create' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/1'))
      create(:visit, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/1'))
    end

    it 'handles update' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/1'))
      visit = create(:visit, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/1'))
      visit.patient_id = 2
      visit.save
      expect(File).to exist(ERICA.image_storage_path.join('1/1/2/1'))
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/1'))
    end

    it 'handles destroy' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/1'))
      visit = create(:visit, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/1'))
      visit.destroy
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/1'))
    end
  end

  describe 'scope #by_study_ids' do
    before :each do
      @study1     = create(:study)
      @center11   = create(:center, study: @study1)

      @patient111 = create(:patient, center: @center11)
      @visit1111  = create(:visit, patient: @patient111)
      @visit1112  = create(:visit, patient: @patient111)

      @center12   = create(:center, study: @study1)
      @patient121 = create(:patient, center: @center12)
      @visit1211  = create(:visit, patient: @patient121)
      @visit1212  = create(:visit, patient: @patient121)

      @study2     = create(:study)
      @center21   = create(:center, study: @study2)

      @patient211 = create(:patient, center: @center21)
      @visit2111  = create(:visit, patient: @patient211)
      @visit2112  = create(:visit, patient: @patient211)

      @center22   = create(:center, study: @study2)
      @patient221 = create(:patient, center: @center22)
      @visit2211  = create(:visit, patient: @patient221)
      @visit2212  = create(:visit, patient: @patient221)

      @study3     = create(:study)
      @center31   = create(:center, study: @study3)

      @patient311 = create(:patient, center: @center31)
      @visit3111  = create(:visit, patient: @patient311)
      @visit3112  = create(:visit, patient: @patient311)

      @center32   = create(:center, study: @study3)
      @patient321 = create(:patient, center: @center32)
      @visit3211  = create(:visit, patient: @patient321)
      @visit3212  = create(:visit, patient: @patient321)
    end

    it 'returns the matched visits for a single study' do
      expect(Visit.by_study_ids(@study1.id))
        .to match_array [
          @visit1111, @visit1112, @visit1211, @visit1212
        ]
    end

    it 'returns the matched visits by study' do
      expect(Visit.by_study_ids(@study1.id, @study3.id))
        .to match_array [
          @visit1111, @visit1112, @visit1211, @visit1212,
          @visit3111, @visit3112, @visit3211, @visit3212
        ]
      expect(Visit.by_study_ids([@study1.id, @study3.id]))
        .to match_array [
          @visit1111, @visit1112, @visit1211, @visit1212,
          @visit3111, @visit3112, @visit3211, @visit3212
        ]
    end
  end
end
