describe SendInstantNotificationEmail do
  it { is_expected.to be_processed_in :notifications }
  it { is_expected.to be_retryable(5) }

  it 'enqueues another send throttled notification email job' do
    SendInstantNotificationEmail.perform_async(1)
    expect(SendInstantNotificationEmail).to have_enqueued_job(1)
  end

  context 'with existing throttled notifications' do
    before(:each) do
      @user = create(:user)
      @profile = create(:notification_profile, users: [@user], maximum_email_throttling_delay: 0)
      @notification = create(:notification, notification_profile: @profile, user: @user)
    end

    it 'enqueues another emailing job' do
      SendInstantNotificationEmail.new.perform(@notification.id)
      expect(NotificationMailer)
        .to receive(:instant_notification_email)
        .with(@notification)
        .and_call_original
      expect {
        SendInstantNotificationEmail.new.perform(@notification.id)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
