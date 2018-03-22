describe ImageDrop do
  before(:each) do
    allow(subject.send(:object)).to receive(:image_storage_path)
    allow(subject.send(:object)).to receive(:absolute_image_storage_path)
  end

  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }

  it { is_expected.to belongs_to(:image_series) }
  it { is_expected.to respond_to(:series) }

  it { is_expected.to delegate(:image_storage_path).to(:object) }
  it { is_expected.to delegate(:absolute_image_storage_path).to(:object) }
end
