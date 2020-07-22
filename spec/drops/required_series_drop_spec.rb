describe RequiredSeriesDrop do
  before(:each) do
    allow(subject.send(:object)).to receive(:tqc_user).and_return(create(:user))
  end

  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }

  it { is_expected.to belongs_to(:image_series) }
  it { is_expected.to belongs_to(:visit) }
  it { is_expected.to belongs_to(:tqc_user) }

  it { is_expected.to have_attribute(:name) }
  it { is_expected.to have_attribute(:tqc_results) }
  it { is_expected.to have_attribute(:tqc_state) }
  it { is_expected.to have_attribute(:tqc_comment) }
  it { is_expected.to have_attribute(:tqc_version) }
  it { is_expected.to have_attribute(:tqc_date) }

  it 'returns the correct tqc_user as drop' do
    expect(subject.tqc_user).to be_a(UserDrop)
  end
end

