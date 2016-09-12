describe SendThrottledNotificationEmail do
  it { is_expected.to be_processed_in :notifications }
  it { is_expected.to be_retryable(5) }

  it 'enqueues another send throttled notification email job' do
    SendThrottledNotificationEmail.perform_async(1, 1, [1, 2, 3])
    expect(SendThrottledNotificationEmail).to have_enqueued_sidekiq_job(1, 1, [1, 2, 3])
  end

  context 'with existing throttled notifications' do
    before(:each) do
      @user = create(:user)
      @profile = create(:notification_profile, users: [@user], maximum_email_throttling_delay: 24*60*60)
      @notification = create(:notification, notification_profile: @profile, user: @user)
    end

    it 'enqueues another emailing job' do
      SendThrottledNotificationEmail.new.perform(@user.id, @profile.id, [@notification.id])
      expect(NotificationMailer)
        .to receive(:throttled_notification_email)
        .with(@user, @profile, [@notification])
        .and_call_original
      expect {
        SendThrottledNotificationEmail.new.perform(@user.id, @profile.id, [@notification.id])
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
