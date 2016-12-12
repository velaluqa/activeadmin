describe VisitDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:state) }
  it { should have_attribute(:visit_type) }
  it { should have_attribute(:visit_number) }
  it { should have_attribute(:description) }
  it { should have_attribute(:required_series) }
  it { should have_attribute(:assigned_image_series_index) }
  it { should have_attribute(:mqc_comment) }
  it { should have_attribute(:mqc_date) }
  it { should have_attribute(:mqc_results) }
  it { should have_attribute(:mqc_state) }
  it { should have_attribute(:mqc_version) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }
  it { should have_attribute(:domino_unid) }

  it { should belongs_to(:patient) }
  it { should have_many(:image_series) }
  it { should belongs_to(:mqc_user) }
end
