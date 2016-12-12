describe VersionDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:event) }
  it { should have_attribute(:object) }
  it { should have_attribute(:object_changes) }
  it { should have_attribute(:whodunnit) }
  it { should have_attribute(:created_at) }

  it { should belongs_to(:item) }
end
