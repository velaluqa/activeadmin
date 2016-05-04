RSpec.describe Study do
  describe 'scope #by_ids' do
    before :each do
      @study1 = create(:study)
      @study2 = create(:study)
      @study3 = create(:study)
    end

    it 'returns the correct study' do
      expect(Study.by_ids(@study1.id).all)
        .to eq [@study1]
    end
    it 'returns the correct studies' do
      expect(Study.by_ids(@study1.id, @study3.id).all)
        .to eq [@study1, @study3]
      expect(Study.by_ids([@study1.id, @study3.id]).all)
        .to eq [@study1, @study3]
    end
  end
end
