describe UserRoleDrop do
  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }

  it { is_expected.to belongs_to(:user) }
  it { is_expected.to belongs_to(:role) }
  it { is_expected.to belongs_to(:scope_object) }
  it { is_expected.to have_many(:permissions) }
end
