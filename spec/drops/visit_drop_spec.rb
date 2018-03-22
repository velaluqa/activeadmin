describe VisitDrop do
  specify { expect(VisitDrop.new(create(:visit))).to respond_to(:required_series) }

  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:state) }
  it { is_expected.to have_attribute(:visit_type) }
  it { is_expected.to have_attribute(:visit_number) }
  it { is_expected.to have_attribute(:description) }
  it { is_expected.to have_attribute(:assigned_image_series_index) }
  it { is_expected.to have_attribute(:mqc_comment) }
  it { is_expected.to have_attribute(:mqc_date) }
  it { is_expected.to have_attribute(:mqc_results) }
  it { is_expected.to have_attribute(:mqc_state) }
  it { is_expected.to have_attribute(:mqc_version) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }
  it { is_expected.to have_attribute(:domino_unid) }

  it { is_expected.to belongs_to(:patient) }
  it { is_expected.to have_many(:image_series) }
  it { is_expected.to belongs_to(:mqc_user) }
end
