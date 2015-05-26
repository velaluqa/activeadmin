RSpec.describe Center do
  it 'has a valid factory' do
    expect(create(:center)).to be_valid
  end

  describe 'scope #by_study_ids' do
    before :each do
      @study1 = create(:study)
      @center11 = create(:center, study: @study1)
      @center12 = create(:center, study: @study1)
      @study2 = create(:study)
      @center21 = create(:center, study: @study2)
      @center22 = create(:center, study: @study2)
      @study3 = create(:study)
      @center31 = create(:center, study: @study3)
      @center32 = create(:center, study: @study3)
    end

    it 'returns the matched centers for a single study' do
      expect(Center.by_study_ids(@study1.id).all)
        .to match_array [@center11, @center12]
    end

    it 'returns the matched centers for multiple studies' do
      expect(Center.by_study_ids(@study1.id, @study3.id).all)
        .to match_array [@center11, @center12, @center31, @center32]
      expect(Center.by_study_ids([@study1.id, @study3.id]).all)
        .to match_array [@center11, @center12, @center31, @center32]
    end
  end
end
