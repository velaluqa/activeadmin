describe CenterDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:study_id) }
  it { should have_attribute(:name) }
  it { should have_attribute(:code) }
  it { should have_attribute(:domino_unid) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }

  it { should belongs_to(:study) }
  it { should have_many(:patients) }

  describe '#full_name' do
    let(:center) { create(:center) }
    let(:drop) { center.to_liquid }

    it 'returns the correct full name from the model' do
      expect(drop.full_name).to eq center.full_name
    end
  end
end
