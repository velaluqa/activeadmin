describe NotificationDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:triggering_action) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }
  it { should have_attribute(:marked_seen_at) }
  it { should have_attribute(:email_sent_at) }

  it { should belongs_to(:notification_profile) }
  it { should belongs_to(:user) }
  it { should belongs_to(:version) }
  it { should belongs_to(:resource) }
end
