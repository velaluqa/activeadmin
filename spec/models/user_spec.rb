RSpec.describe User do
  it { should have_and_belong_to_many(:notification_profiles) }

  it 'validates the email address' do
    user = build(:user, email: nil)
    expect(user).to_not be_valid
    user = build(:user, email: '')
    expect(user).to_not be_valid
    user = build(:user, email: 'foo@bar')
    expect(user).to_not be_valid
    user = build(:user, email: 'foo@bar.berlin')
    expect(user).to be_valid
  end

  describe 'given signature_password' do
    before(:each) do
      @user = create(:user, signature_password: 'somepass')
    end

    it 'generates a keypair' do
      expect(@user.public_keys.count).to eq 1
    end
  end

  describe 'not given signature_password' do
    before(:each) do
      @user = create(:user)
    end

    it 'does not generate a keypair' do
      expect(@user.public_keys.count).to eq 0
    end
  end

  describe '#permission_matrix' do
    describe 'user with two roles' do
      before(:each) do
        @role1 = create(:role, with_permissions: {
                          Study => %i(manage read),
                          Image => %i(read)
                        })
        @role2 = create(:role, with_permissions: {
                          Study => %i(manage read),
                          Center => %i(manage read),
                          Visit => %i(assign_required_series)
                        })
        @user = create(:user, with_user_roles: [@role1, @role2])
      end

      it 'only keeps :manage' do
        expected = {
          'Study' => %i(manage),
          'Center' => %i(manage),
          'Image' => %i(read),
          'Visit' => %i(assign_required_series),
          'User' => %i(manage),
          'PublicKey' => %i(manage)
        }
        expect(@user.permission_matrix).to eq(expected)
      end
    end

    describe 'user with scoped roles' do

    end
  end

  describe '#generate_keypair' do
    before(:each) do
      @user = create(:user, signature_password: 'somepass')
      @private_key = @user.private_key
      @public_key = @user.public_key
      @public_key_record = @user.active_public_key
      @user.generate_keypair('otherpass')
      @public_key_record.reload
    end

    it 'updates the keys' do
      expect(@user.public_key).not_to eq @public_key
      expect(@user.private_key).not_to eq @private_key
    end

    it 'deactivates old public keys' do
      expect(@public_key_record.active).to be_falsy
    end
  end
end
