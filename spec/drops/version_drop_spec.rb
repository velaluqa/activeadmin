describe VersionDrop do
  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:event) }
  it { is_expected.to have_attribute(:object) }
  it { is_expected.to have_attribute(:object_changes) }
  it { is_expected.to have_attribute(:whodunnit) }
  it { is_expected.to have_attribute(:created_at) }

  it { is_expected.to belongs_to(:item) }
end
