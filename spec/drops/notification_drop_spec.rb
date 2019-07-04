describe NotificationDrop do
  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:triggering_action) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }
  it { is_expected.to have_attribute(:marked_seen_at) }
  it { is_expected.to have_attribute(:email_sent_at) }

  it { is_expected.to belongs_to(:notification_profile) }
  it { is_expected.to belongs_to(:user) }
  it { is_expected.to belongs_to(:version) }

  describe '#resource' do
    it { is_expected.to respond_to(:resource) }
  end
end
