describe PermissionDrop do
  before(:each) do
    allow(subject.send(:object)).to receive(:ability)
  end

  it { should have_attribute(:id) }
  it { should have_attribute(:activity) }
  it { should have_attribute(:subject) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }

  it { should belongs_to(:role) }
  it { should have_many(:users) }

  it { should delegate(:ability).to(:object) }
end
