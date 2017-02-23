describe TriggerNotificationProfiles do
  it { is_expected.to be_processed_in :notifications }
  it { is_expected.to be_retryable(5) }
end
