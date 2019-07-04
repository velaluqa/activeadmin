describe BackgroundJobDrop do
  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:progress) }
  it { is_expected.to have_attribute(:error_message) }
  it { is_expected.to have_attribute(:results) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }
  it { is_expected.to have_attribute(:completed_at) }

  it { is_expected.to belongs_to(:user) }

  it { is_expected.to respond_to(:finished?) }
  it { is_expected.to respond_to(:succeeded?) }
  it { is_expected.to respond_to(:failed?) }
end
