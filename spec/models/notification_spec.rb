RSpec.describe Notification do
  it { should belong_to(:notification_profile) }
  it { should belong_to(:user) }
  it { should belong_to(:version) }
  it { should belong_to(:resource) }

  describe 'model' do
    it 'is invalid without user' do
      expect(build(:notification, user: nil)).not_to be_valid
    end

    it 'is invalid without profile' do
      expect(build(:notification, notification_profile: nil)).not_to be_valid
    end

    it 'is invalid without resource' do
      expect(build(:notification, resource: nil)).not_to be_valid
    end
  end

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

  describe '#email_throttling_delay' do
    before(:each) do
      @user = create(:user, email_throttling_delay: 0)
      @profile = create(:notification_profile, maximum_email_throttling_delay: 0)
      @notification1 = create(:notification)
      @notification2 = create(:notification, user: @user)
      @notification3 = create(:notification, notification_profile: @profile)
    end

    it 'returns the minimum delay of profile, user or system-wide email_throttling_delay' do
      expect(@notification1.email_throttling_delay).to eq ERICA.maximum_email_throttling_delay
      expect(@notification2.email_throttling_delay).to eq 0
      expect(@notification3.email_throttling_delay).to eq 0
    end
  end

  describe '#throttled?' do
    before(:each) do
      @notification = create(:notification)
    end

    it 'returns false if email_throttling_delay is greater than 0' do
      expect(@notification).to receive(:email_throttling_delay).and_return(0)
      expect(@notification).not_to be_throttled
    end

    it 'returns true if email_throttling_delay is greater than 0' do
      expect(@notification).to receive(:email_throttling_delay).and_return(5)
      expect(@notification).to be_throttled
    end
  end

  describe 'non-throttled notification', transactional_spec: true do
    describe 'on create' do
      before(:each) do
        @user = create(:user)
        @visit = create(:visit)
        @profile = create(:notification_profile, maximum_email_throttling_delay: 0)
      end

      it 'schedules an instant notification job' do
        expect(SendInstantNotificationEmail).not_to have_enqueued_sidekiq_job
        notification = @profile.notifications.create(user: @user, triggering_action:'create', resource: @visit)
        expect(SendInstantNotificationEmail).to have_enqueued_sidekiq_job(notification.id)
      end
    end
  end
end
