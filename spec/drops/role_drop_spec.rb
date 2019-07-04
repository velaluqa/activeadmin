describe RoleDrop do
  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:title) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }

  it { is_expected.to have_many(:user_roles) }
  it { is_expected.to have_many(:users) }
  it { is_expected.to have_many(:permissions) }
  it { is_expected.to have_many(:notification_profiles) }
end
