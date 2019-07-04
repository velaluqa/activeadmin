describe PermissionDrop do
  before(:each) do
    allow(subject.send(:object)).to receive(:ability)
  end

  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:activity) }
  it { is_expected.to have_attribute(:subject) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }

  it { is_expected.to belongs_to(:role) }
  it { is_expected.to have_many(:users) }

  it { is_expected.to delegate(:ability).to(:object) }
end
