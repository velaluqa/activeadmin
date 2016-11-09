describe NotificationProfileDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:title) }
  it { should have_attribute(:description) }
  it { should have_attribute(:notification_type) }
  it { should have_attribute(:is_enabled) }
  it { should have_attribute(:triggering_actions) }
  it { should have_attribute(:triggering_resource) }
  it { should have_attribute(:filters) }
  it { should have_attribute(:maximum_email_throttling_delay) }
  it { should have_attribute(:only_authorized_recipients) }
  it { should have_attribute(:updated_at) }
  it { should have_attribute(:created_at) }

  it { should have_many(:notifications) }
end
