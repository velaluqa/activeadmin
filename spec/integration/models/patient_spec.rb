RSpec.describe Patient do
  it 'has a valid factory' do
    expect(create(:patient)).to be_valid
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
