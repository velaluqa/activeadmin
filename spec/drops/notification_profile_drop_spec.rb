describe NotificationProfileDrop do
  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:title) }
  it { is_expected.to have_attribute(:description) }
  it { is_expected.to have_attribute(:notification_type) }
  it { is_expected.to have_attribute(:is_enabled) }
  it { is_expected.to have_attribute(:triggering_actions) }
  it { is_expected.to have_attribute(:triggering_resource) }
  it { is_expected.to have_attribute(:filters) }
  it { is_expected.to have_attribute(:maximum_email_throttling_delay) }
  it { is_expected.to have_attribute(:only_authorized_recipients) }
  it { is_expected.to have_attribute(:updated_at) }
  it { is_expected.to have_attribute(:created_at) }

  it { is_expected.to have_many(:notifications) }
end
