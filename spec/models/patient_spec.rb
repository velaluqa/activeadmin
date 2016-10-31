RSpec.describe Patient do
  describe 'scope ::searchable' do
    it 'selects search fields' do
      center = create(:center, code: 'Foo')
      patient = create(:patient, subject_id: 'Bar', center: center)
      expect(Patient.searchable.as_json)
        .to eq [{
                  'id' => nil,
                  'study_id' => patient.center.study_id,
                  'text' => 'FooBar',
                  'result_id' => patient.id,
                  'result_type' => 'Patient'
                }]
    end
  end

  describe 'image storage' do
    before(:each) do
      @study = create(:study, id: 1)
      @center = create(:center, id: 1, study: @study)
      @center2 = create(:center, id: 2, study: @study)
      expect(File).to exist(ERICA.image_storage_path.join('1/1'))
      expect(File).to exist(ERICA.image_storage_path.join('1/2'))
    end

    it 'handles create' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1'))
      create(:patient, id: 1, center: @center)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned'))
    end

    it 'handles update' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1'))
      center = create(:patient, id: 1, center: @center)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1'))
      center.center_id = 2
      center.save
      expect(File).to exist(ERICA.image_storage_path.join('1/2/1'))
      expect(File).to exist(ERICA.image_storage_path.join('1/2/1/__unassigned'))
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1'))
    end

    it 'handles destroy' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1'))
      patient = create(:patient, id: 1, center: @center)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1'))
      patient.destroy
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1'))
    end
  end

  describe 'scope #by_study_ids' do
    before :each do
      @study1 = create(:study)
      @center11 = create(:center, study: @study1)
      @patient111 = create(:patient, center: @center11)
      @patient112 = create(:patient, center: @center11)
      @center12 = create(:center, study: @study1)
      @patient121 = create(:patient, center: @center12)
      @patient122 = create(:patient, center: @center12)
      @study2 = create(:study)
      @center21 = create(:center, study: @study2)
      @patient211 = create(:patient, center: @center21)
      @patient212 = create(:patient, center: @center21)
      @center22 = create(:center, study: @study2)
      @patient221 = create(:patient, center: @center22)
      @patient222 = create(:patient, center: @center22)
      @study3 = create(:study)
      @center31 = create(:center, study: @study3)
      @patient311 = create(:patient, center: @center31)
      @patient312 = create(:patient, center: @center31)
      @center32 = create(:center, study: @study3)
      @patient321 = create(:patient, center: @center32)
      @patient322 = create(:patient, center: @center32)
    end

    it 'returns the matched patients for a single study' do
      expect(Patient.by_study_ids(@study1.id))
        .to match_array [
          @patient111, @patient112, @patient121, @patient122
        ]
    end

    it 'returns the matched patients for a single study' do
      expect(Patient.by_study_ids(@study1.id, @study3.id))
        .to match_array [
          @patient111, @patient112, @patient121, @patient122,
          @patient311, @patient312, @patient321, @patient322
        ]
      expect(Patient.by_study_ids([@study1.id, @study3.id]))
        .to match_array [
          @patient111, @patient112, @patient121, @patient122,
          @patient311, @patient312, @patient321, @patient322
        ]
    end
  end
end
