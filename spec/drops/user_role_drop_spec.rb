describe UserRoleDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }

  it { should belongs_to(:user) }
  it { should belongs_to(:role) }
  it { should belongs_to(:scope_object) }
  it { should have_many(:permissions) }
end
