describe SendThrottledNotificationEmails do
  it { is_expected.to be_processed_in :notifications }
  it { is_expected.to be_retryable(5) }

  it 'enqueues another send throttled notification email job' do
    SendThrottledNotificationEmails.perform_async('hourly')
    expect(SendThrottledNotificationEmails).to have_enqueued_job('hourly')
  end

  context 'with existing throttled notifications' do
    before(:each) do
      @user1 = create(:user)
      @user2 = create(:user)
      @profile = create(:notification_profile, users: [@user1], maximum_email_throttling_delay: 24*60*60)
      @notification1 = create(:notification, notification_profile: @profile, user: @user1)
      @notification2 = create(:notification, notification_profile: @profile, user: @user2)
      @notification3 = create(:notification, notification_profile: @profile, user: @user2, email_sent_at: 1.minute.ago, created_at: 2.minutes.ago)
    end

    it 'enqueues other emailing jobs' do
      SendThrottledNotificationEmails.new.perform(24*60*60)
      expect(SendThrottledNotificationEmail).to have_enqueued_job(@user1.id, @profile.id, [@notification1.id])
      expect(SendThrottledNotificationEmail).to have_enqueued_job(@user2.id, @profile.id, [@notification2.id])
    end
  end
end
