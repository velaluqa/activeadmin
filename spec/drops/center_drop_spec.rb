describe CenterDrop do
  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:study_id) }
  it { is_expected.to have_attribute(:name) }
  it { is_expected.to have_attribute(:code) }
  it { is_expected.to have_attribute(:domino_unid) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }

  it { is_expected.to belongs_to(:study) }
  it { is_expected.to have_many(:patients) }

  describe '#full_name' do
    let(:center) { create(:center) }
    let(:drop) { center.to_liquid }

    it 'returns the correct full name from the model' do
      expect(drop.full_name).to eq center.full_name
    end
  end
end
