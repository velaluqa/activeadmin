RSpec.describe Center do
  describe 'destroy' do
    let!(:center) { create(:center) }
    let!(:user) { create(:user) }
    let!(:user_role) { create(:user_role, scope_object: center, user: user) }

    it 'destroys related user roles' do
      expect do
        center.destroy
      end.to change(UserRole, :count).by(-1)
    end
  end

  describe 'scope ::searchable' do
    it 'selects search fields' do
      center = create(:center, name: 'FooCenter')
      expect(Center.searchable.as_json).to(
        eq(
          [
            {
              'id' => nil,
              'study_id' => center.study_id,
              'study_name' => center.study.name,
              'text' => "#{center.code} - FooCenter",
              'result_id' => center.id.to_s,
              'tag_list' => [],
              'result_type' => 'Center'
            }
          ]
        )
      )
    end
  end

  describe '::granted_for' do
    let!(:study1) { create(:study) }
    let!(:center1) { create(:center, study: study1) }
    let!(:patient1) { create(:patient, center: center1) }
    let!(:study2) { create(:study) }
    let!(:center2) { create(:center, study: study2) }
    let!(:patient2) { create(:patient, center: center2) }

    context 'ability read Center system-wide' do
      let!(:role) { create(:role, with_permissions: { Center => :read }) }
      let!(:user) { create(:user, with_user_roles: [role]) }
      let(:granted_centers) { Center.granted_for(user: user, activity: :read) }

      it 'returns all centers' do
        expect(granted_centers).to include(center1)
        expect(granted_centers).to include(center2)
      end
    end

    context 'ability read center1' do
      let!(:role) { create(:role, with_permissions: { Center => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, center1]]) }
      let(:granted_centers) { Center.granted_for(user: user, activity: :read) }

      it 'returns only center1' do
        expect(granted_centers).to include(center1)
        expect(granted_centers).not_to include(center2)
      end
    end

    context 'ability read center and study1' do
      let!(:role) { create(:role, with_permissions: { Study => :read, Center => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, study1]]) }
      let(:granted_centers) { Center.granted_for(user: user, activity: :read) }

      it 'returns only center1' do
        expect(granted_centers).to include(center1)
        expect(granted_centers).not_to include(center2)
      end
    end

    context 'ability read center and patient1' do
      let!(:role) { create(:role, with_permissions: { Center => :read, Patient => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, patient1]]) }
      let(:granted_centers) { Center.granted_for(user: user, activity: :read) }

      it 'returns only center1' do
        expect(granted_centers).to include(center1)
        expect(granted_centers).not_to include(center2)
      end
    end
  end

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

  describe 'having patients' do
    let!(:center) { create(:center) }
    let!(:patient) { create(:patient, center: center) }

    it 'does not allow destruction' do
      is_destroyed = center.destroy
      expect(is_destroyed).to be_falsy
      expect(center.errors[:study]).to eq ['You cannot delete a center which has patients associated.']
    end
  end

  it 'does not allow reassignment of study' do
    other_study = create(:study)
    center = create(:center)
    center.study = other_study

    expect(center.save).to be_falsy
    expect(center.errors[:study]).to eq(['A center cannot be reassigned to a different study.'])
  end

  describe 'versioning' do
    describe 'create' do
      before(:each) do
        @center = create(:center)
        @study_id = @center.study_id
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Center').last
        expect(version.study_id).to eq @study_id
      end
    end
    describe 'update' do
      before(:each) do
        @center = create(:center)
        @study_id = @center.study_id
        @center.name = 'New Name'
        @center.save!
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Center').last
        expect(version.event).to eq 'update'
        expect(version.study_id).to eq @study_id
      end
    end
    describe 'destroy' do
      before(:each) do
        @center = create(:center)
        @study_id = @center.study_id
        @center.destroy
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Center').last
        expect(version.event).to eq 'destroy'
        expect(version.study_id).to eq @study_id
      end
    end
  end

  describe "callback #eventually_update_dicom_tags" do
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study, code: "10") }
    let!(:patient) { create(:patient, center: center, subject_id: "10") }
    let!(:image_series) { create(:image_series, with_images: 1, patient: patient) }
    let!(:user) { create(:user) }
    let(:image) { image_series.images.first }

    describe "updating `code`" do
      it 'updates DICOM tag `patient_name` for all associated images through background job' do
        expect(image.dicom.patients_name.value).to eq("1010")

        center.code = "20"
        center.save

        Sidekiq::Worker.drain_all

        expect(image.dicom.patients_name.value).to eq("2010")
      end
    end
  end
end
