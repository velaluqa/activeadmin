describe RoleDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:title) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }

  it { should have_many(:user_roles) }
  it { should have_many(:users) }
  it { should have_many(:permissions) }
  it { should have_many(:notification_profiles) }
end
