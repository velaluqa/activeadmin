describe ImageDrop do
  before(:each) do
    allow(subject.send(:object)).to receive(:image_storage_path)
    allow(subject.send(:object)).to receive(:absolute_image_storage_path)
  end

  it { should have_attribute(:id) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }

  it { should belongs_to(:image_series) }
  it { should respond_to(:series) }

  it { should delegate(:image_storage_path).to(:object) }
  it { should delegate(:absolute_image_storage_path).to(:object) }
end
