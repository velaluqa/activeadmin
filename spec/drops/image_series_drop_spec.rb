describe ImageSeriesDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:visit_id) }
  it { should have_attribute(:patient_id) }
  it { should have_attribute(:state) }
  it { should have_attribute(:series_number) }
  it { should have_attribute(:name) }
  it { should have_attribute(:comment) }
  it { should have_attribute(:imaging_date) }
  it { should have_attribute(:properties) }
  it { should have_attribute(:properties_version) }
  it { should have_attribute(:domino_unid) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }

  it { should belongs_to(:visit) }
  it { should belongs_to(:patient) }
  it { should have_many(:images) }
end
