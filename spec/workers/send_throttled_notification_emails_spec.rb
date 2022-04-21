describe SendThrottledNotificationEmails, mailer: :test do
  it { is_expected.to be_processed_in :notifications }
  it { is_expected.to be_retryable(5) }

  it 'enqueues another send throttled notification email job' do
    SendThrottledNotificationEmails.perform_async('hourly')
    expect(SendThrottledNotificationEmails).to have_enqueued_sidekiq_job('hourly')
    allow(Rails.application.config).to receive(:maximum_email_throttling_delay).and_return(30 * 24 * 60 * 60)
  end

  context 'with existing throttled notifications' do
    before(:each) do
      @user1 = create(:user)
      @user2 = create(:user, email_throttling_delay: 60 * 60)
      @user3 = create(:user)
      @profile1 = create(:notification_profile, users: [@user1, @user2, @user3], maximum_email_throttling_delay: nil)
      @profile2 = create(:notification_profile, users: [@user1, @user2, @user3], maximum_email_throttling_delay: 24 * 60 * 60)
      @notification1 = create(:notification, notification_profile: @profile1, user: @user1)
      @notification2 = create(:notification, notification_profile: @profile1, user: @user2)
      @notification3 = create(:notification, notification_profile: @profile1, user: @user3, email_sent_at: 1.minute.ago, created_at: 2.minutes.ago)
      @notification4 = create(:notification, notification_profile: @profile2, user: @user1)
      @notification5 = create(:notification, notification_profile: @profile2, user: @user2)
      @notification6 = create(:notification, notification_profile: @profile2, user: @user3, email_sent_at: 1.minute.ago, created_at: 2.minutes.ago)
    end

    it 'enqueues pending emailing jobs for `hourly`' do
      SendThrottledNotificationEmails.new.perform(60 * 60)
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user1.id, @profile1.id, [@notification1.id])
      expect(SendThrottledNotificationEmail).to have_enqueued_sidekiq_job(@user2.id, @profile1.id, [@notification2.id])
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user3.id, @profile1.id, [@notification3.id])

      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user1.id, @profile2.id, [@notification4.id])
      expect(SendThrottledNotificationEmail).to have_enqueued_sidekiq_job(@user2.id, @profile2.id, [@notification5.id])
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user3.id, @profile2.id, [@notification6.id])
    end

    it 'enqueues pending emailing jobs for `daily`' do
      SendThrottledNotificationEmails.new.perform(24 * 60 * 60)
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user1.id, @profile1.id, [@notification1.id])
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user2.id, @profile1.id, [@notification2.id])
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user3.id, @profile1.id, [@notification3.id])

      expect(SendThrottledNotificationEmail).to have_enqueued_sidekiq_job(@user1.id, @profile2.id, [@notification4.id])
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user2.id, @profile2.id, [@notification5.id])
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user3.id, @profile2.id, [@notification6.id])
    end

    it 'enqueues pending emailing jobs for `monthly`' do
      SendThrottledNotificationEmails.new.perform('monthly')
      expect(SendThrottledNotificationEmail).to have_enqueued_sidekiq_job(@user1.id, @profile1.id, [@notification1.id])
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user2.id, @profile1.id, [@notification2.id])
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user3.id, @profile1.id, [@notification3.id])

      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user1.id, @profile2.id, [@notification4.id])
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user2.id, @profile2.id, [@notification5.id])
      expect(SendThrottledNotificationEmail).not_to have_enqueued_sidekiq_job(@user3.id, @profile2.id, [@notification6.id])
    end
  end
end
