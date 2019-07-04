describe ImageSeriesDrop do
  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:visit_id) }
  it { is_expected.to have_attribute(:patient_id) }
  it { is_expected.to have_attribute(:state) }
  it { is_expected.to have_attribute(:series_number) }
  it { is_expected.to have_attribute(:name) }
  it { is_expected.to have_attribute(:comment) }
  it { is_expected.to have_attribute(:imaging_date) }
  it { is_expected.to have_attribute(:properties) }
  it { is_expected.to have_attribute(:properties_version) }
  it { is_expected.to have_attribute(:domino_unid) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }

  it { is_expected.to belongs_to(:visit) }
  it { is_expected.to belongs_to(:patient) }
  it { is_expected.to have_many(:images) }
end
