describe BackgroundJobDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:legacy_id) }
  it { should have_attribute(:progress) }
  it { should have_attribute(:error_message) }
  it { should have_attribute(:completed) }
  it { should have_attribute(:successful) }
  it { should have_attribute(:results) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }
  it { should have_attribute(:completed_at) }

  it { should belongs_to(:user) }

  it { should respond_to(:finished?) }
  it { should respond_to(:succeeded?) }
  it { should respond_to(:failed?) }
end
