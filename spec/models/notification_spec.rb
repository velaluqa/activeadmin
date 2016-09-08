RSpec.describe Notification do
  it { should belong_to(:notification_profile) }
  it { should belong_to(:user) }
  it { should belong_to(:version) }
  it { should belong_to(:resource) }

  describe 'scope ::pending' do
    before(:each) do
      @not1 = create(:notification)
      @not2 = create(:notification, email_sent_at: 5.minutes.ago, created_at: 10.minutes.ago)
    end

    it 'returns only notifications without `email_sent_at` date' do
      expect(Notification.pending).to include(@not1)
      expect(Notification.pending).not_to include(@not2)
    end
  end

  describe 'scope ::for(user)' do
    before(:each) do
      @user1 = create(:user)
      @user2 = create(:user)
      @not1 = create(:notification, user: @user1)
      @not2 = create(:notification, user: @user2)
    end

    it 'returns only notifications for given user object' do
      expect(Notification.for(@user1)).to include(@not1)
      expect(Notification.for(@user1)).not_to include(@not2)
      expect(Notification.for(@user2)).not_to include(@not1)
      expect(Notification.for(@user2)).to include(@not2)
    end

    it 'returns only notifications for given user id' do
      expect(Notification.for(@user1.id)).to include(@not1)
      expect(Notification.for(@user1.id)).not_to include(@not2)
      expect(Notification.for(@user2.id)).not_to include(@not1)
      expect(Notification.for(@user2.id)).to include(@not2)
    end
  end

  describe 'scope ::of(profile)' do
    before(:each) do
      @profile1 = create(:notification_profile)
      @profile2 = create(:notification_profile)
      @not1 = create(:notification, notification_profile: @profile1)
      @not2 = create(:notification, notification_profile: @profile2)
    end

    it 'returns only notifications of given profile object' do
      expect(Notification.of(@profile1)).to include(@not1)
      expect(Notification.of(@profile1)).not_to include(@not2)
      expect(Notification.of(@profile2)).not_to include(@not1)
      expect(Notification.of(@profile2)).to include(@not2)
    end

    it 'returns only notifications of given profile id' do
      expect(Notification.of(@profile1.id)).to include(@not1)
      expect(Notification.of(@profile1.id)).not_to include(@not2)
      expect(Notification.of(@profile2.id)).not_to include(@not1)
      expect(Notification.of(@profile2.id)).to include(@not2)
    end
  end
end
