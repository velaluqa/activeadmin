RSpec.describe Center do
  describe 'image storage' do
    before(:each) do
      @study = create(:study, id: 1)
      @study2 = create(:study, id: 2)
      expect(File).to exist(ERICA.image_storage_path.join('1'))
      expect(File).to exist(ERICA.image_storage_path.join('2'))
    end

    it 'handles create' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1'))
      create(:center, id: 1, study: @study)
      expect(File).to exist(ERICA.image_storage_path.join('1/1'))
    end

    # TODO: Currently the change of a study for a center is not
    # allowed. Remember to add this, when a center may be allowed to
    # switch studies.
    #
    # it 'handles update' do
    #   expect(File).not_to exist(ERICA.image_storage_path.join('1/1'))
    #   center = create(:center, id: 1, study: @study)
    #   expect(File).to exist(ERICA.image_storage_path.join('1/1'))
    #   center.study_id = 2
    #   center.save!
    #   expect(File).to exist(ERICA.image_storage_path.join('2/1'))
    #   expect(File).not_to exist(ERICA.image_storage_path.join('1/1'))
    # end

    it 'handles destroy' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1'))
      center = create(:center, id: 1, study: @study)
      expect(File).to exist(ERICA.image_storage_path.join('1/1'))
      center.destroy
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1'))
    end
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
