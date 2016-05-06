RSpec.describe Ability do
  before(:each) do
    @study1        = create(:study)
    @center1       = create(:center, study: @study1)
    @patient1      = create(:patient, center: @center1)
    @visit1        = create(:visit, patient: @patient1)
    @image_series1 = create(:image_series, patient: @patient1, visit: @visit1)
    @image1        = create(:image, image_series: @image_series1)

    @study2        = create(:study)
    @center2       = create(:center, study: @study2)
    @patient2      = create(:patient, center: @center2)
    @visit2        = create(:visit, patient: @patient2)
    @image_series2 = create(:image_series, patient: @patient2, visit: @visit2)
    @image2        = create(:image, image_series: @image_series2)

    @version       = create(:version)

    @some_user     = create(:user)
  end

  describe 'for application administrator' do
    before(:each) do
      @current_user = create(:user, is_root_user: true)
      @ability = Ability.new(@current_user)
    end

    Ability::ACTIVITIES.keys.each do |model|
      it "allows managing #{model}" do
        expect(@ability.can?(:manage, model)).to be_truthy
      end
    end
  end

  describe 'for user without permissions, it' do
    before(:each) do
      @public_key = create(:public_key)
      @current_user = create(:user, public_keys: [@public_key])
      @ability = Ability.new(@current_user)
    end

    it 'allows the user to manage his own user account' do
      expect(@ability.can?(:manage, @current_user)).to be_truthy
    end

    it 'allows the user to manage his own public keys' do
      expect(@ability.can?(:manage, @public_key)).to be_truthy
    end
  end

  describe 'for user with system permissions only' do
    before(:each) do
      @role1 = create(:role, with_permissions: { manage: Study })
      @role2 = create(:role, with_permissions: { read: Image })
      @current_user = create(:user, with_user_roles: [@role1, @role2])
      @ability = Ability.new(@current_user)
    end

    it 'allows managing all studies' do
      expect(@ability.can?(:manage, Study)).to be_truthy
      expect(@ability.can?(:manage, @study1)).to be_truthy
      expect(@ability.can?(:manage, @study2)).to be_truthy
    end

    it 'allows reading all images' do
      expect(@ability.can?(:read, Image)).to be_truthy
      expect(@ability.can?(:read, @image1)).to be_truthy
      expect(@ability.can?(:read, @image2)).to be_truthy
    end

    it 'denies updating an image' do
      expect(@ability.can?(:update, Image)).to be_truthy
      expect(@ability.can?(:update, @image1)).to be_falsy
      expect(@ability.can?(:update, @image2)).to be_falsy
    end

    it 'denies non-authorized activity and subjects' do
      expect(@ability.can?(:update, ImageSeries)).to be_truthy
      expect(@ability.can?(:update, @image_series1)).to be_falsy
      expect(@ability.can?(:update, @image_series2)).to be_falsy
    end

    it 'scopes all studies' do
      expect(Study.accessible_by(@ability).pluck(:id)).to match_array Study.pluck(:id)
    end

    it 'scopes all images' do
      expect(Image.accessible_by(@ability).pluck(:id)).to match_array Image.pluck(:id)
    end
  end

  describe 'for user with scoped permissions only, it' do
    before(:each) do
      @role1 = create(:role, with_permissions: { manage: Study })
      @role2 = create(:role, with_permissions: { read: Image })
      @current_user = create(:user, with_user_roles:
                                      [
                                        [@role1, @study1],
                                        [@role2, @study1]
                                      ])
      @ability = Ability.new(@current_user)
    end

    it 'allows managing all studies' do
      expect(@ability.can?(:manage, Study)).to be_truthy
      expect(@ability.can?(:manage, @study1)).to be_truthy
      expect(@ability.can?(:manage, @study2)).to be_falsy
    end

    it 'allows reading image 1 only' do
      expect(@ability.can?(:read, Image)).to be_truthy
      expect(@ability.can?(:read, @image1)).to be_truthy
      expect(@ability.can?(:read, @image2)).to be_falsy
    end

    it 'denies updating an image' do
      expect(@ability.can?(:update, Image)).to be_truthy
      expect(@ability.can?(:update, @image1)).to be_falsy
      expect(@ability.can?(:update, @image2)).to be_falsy
    end

    it 'denies non-authorized activity and subjects' do
      expect(@ability.can?(:update, ImageSeries)).to be_truthy
      expect(@ability.can?(:update, @image_series1)).to be_falsy
      expect(@ability.can?(:update, @image_series2)).to be_falsy
    end

    it 'scopes only allowed studies' do
      expect(Study.accessible_by(@ability)).to match_array [@study1]
    end

    it 'scopes only allowed images' do
      expect(Image.accessible_by(@ability)).to match_array [@image1]
    end
  end

  describe 'for user with doubly scoped permissions, it' do
    before(:each) do
      @role = create(:role, with_permissions: { manage: Study, read: Image })
      @current_user = create(:user, with_user_roles:
                                      [
                                        [@role, @study1],
                                        [@role, @center1]
                                      ])
      @ability = Ability.new(@current_user)
    end

    it 'allows managing study 1' do
      expect(@ability.can?(:manage, Study)).to be_truthy
      expect(@ability.can?(:manage, @study1)).to be_truthy
      expect(@ability.can?(:manage, @study2)).to be_falsy
    end

    it 'allows reading image 1' do
      expect(@ability.can?(:read, Image)).to be_truthy
      expect(@ability.can?(:read, @image1)).to be_truthy
      expect(@ability.can?(:read, @image2)).to be_falsy
    end

    it 'denies updating an image' do
      expect(@ability.can?(:update, Image)).to be_truthy
      expect(@ability.can?(:update, @image1)).to be_falsy
      expect(@ability.can?(:update, @image2)).to be_falsy
    end

    it 'denies non-authorized activity and subjects' do
      expect(@ability.can?(:update, ImageSeries)).to be_truthy
      expect(@ability.can?(:update, @image_series1)).to be_falsy
      expect(@ability.can?(:update, @image_series2)).to be_falsy
    end

    it 'scopes only allowed studies' do
      expect(Study.accessible_by(@ability)).to match_array [@study1]
    end

    it 'scopes only allowed images' do
      expect(Image.accessible_by(@ability)).to match_array [@image1]
    end
  end

  describe 'for user with mixed permissions, it' do
    before(:each) do
      @role1 = create(:role, with_permissions: { manage: [Study, Image] })
      @role2 = create(:role, with_permissions: { read: [Study, Image] })
      @role3 = create(:role, with_permissions: { read: Version })
      @role4 = create(:role, with_permissions: { manage: User })
      @current_user = create(:user, with_user_roles:
                                      [
                                        [@role1, @study1],
                                        @role2,
                                        @role3,
                                        [@role3, @study1]
                                      ])
      @ability = Ability.new(@current_user)
    end

    it 'allows managing study 1' do
      expect(@ability.can?(:manage, Study)).to be_truthy
      expect(@ability.can?(:manage, @study1)).to be_truthy
      expect(@ability.can?(:manage, @study2)).to be_falsy
    end

    it 'allows reading all studies' do
      expect(@ability.can?(:read, Study)).to be_truthy
      expect(@ability.can?(:read, @study1)).to be_truthy
      expect(@ability.can?(:read, @study2)).to be_truthy
    end

    it 'allows reading all images' do
      expect(@ability.can?(:read, Image)).to be_truthy
      expect(@ability.can?(:read, @image1)).to be_truthy
      expect(@ability.can?(:read, @image2)).to be_truthy
    end

    it 'denies updating image 1' do
      expect(@ability.can?(:update, Image)).to be_truthy
      expect(@ability.can?(:update, @image1)).to be_truthy
      expect(@ability.can?(:update, @image2)).to be_falsy
    end

    it 'denies non-authorized activity and subjects' do
      expect(@ability.can?(:update, ImageSeries)).to be_truthy
      expect(@ability.can?(:update, @image_series1)).to be_falsy
      expect(@ability.can?(:update, @image_series2)).to be_falsy
    end

    it 'denies managing users, since its role is scoped' do
      expect(@ability.can?(:manage, User)).to be_truthy
      expect(@ability.can?(:manage, @user)).to be_falsy
      expect(@ability.can?(:manage, @current_user)).to be_truthy
    end

    it 'allows reading unscopable version records system-wide' do
      expect(@ability.can?(:read, Version)).to be_truthy
      expect(@ability.can?(:read, @version)).to be_truthy
    end

    it 'scopes all studies' do
      expect(Study.accessible_by(@ability).pluck(:id)).to match_array Study.pluck(:id)
    end

    it 'scopes all images' do
      expect(Image.accessible_by(@ability).pluck(:id)).to match_array Image.pluck(:id)
    end
  end
end
