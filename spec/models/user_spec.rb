RSpec.describe User do
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
