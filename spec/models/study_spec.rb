RSpec.describe Study do
  describe 'scope ::searchable' do
    it 'selects search fields' do
      study = create(:study, name: 'FooStudy')
      expect(Study.searchable.as_json)
        .to eq [{
                  'id' => nil,
                  'study_id' => study.id,
                  'text' => 'FooStudy',
                  'result_id' => study.id,
                  'result_type' => 'Study'
                }]
    end
  end

  describe 'image storage' do
    it 'handles create' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1'))
      create(:study, id: 1)
      expect(File).to exist(ERICA.image_storage_path.join('1'))
    end

    it 'handles update' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1'))
      study = create(:study, id: 1)
      expect(File).to exist(ERICA.image_storage_path.join('1'))
      study.id = 2
      study.save
      expect(File).to exist(ERICA.image_storage_path.join('2'))
      expect(File).not_to exist(ERICA.image_storage_path.join('1'))
    end

    it 'handles destroy' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1'))
      study = create(:study, id: 1)
      expect(File).to exist(ERICA.image_storage_path.join('1'))
      study.destroy
      expect(File).not_to exist(ERICA.image_storage_path.join('1'))
    end
  end

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
