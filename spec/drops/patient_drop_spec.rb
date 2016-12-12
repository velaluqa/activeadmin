describe PatientDrop do
  before(:each) do
    allow(subject.send(:object)).to receive(:domino_patient_number)
  end

  it { should have_attribute(:id) }
  it { should have_attribute(:subject_id) }
  it { should have_attribute(:images_folder) }
  it { should have_attribute(:export_history) }
  it { should have_attribute(:data) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }
  it { should have_attribute(:domino_unid) }

  it { should belongs_to(:center) }
  it { should have_many(:visits) }
  it { should have_many(:image_series) }

  it { should delegate(:domino_patient_number).to(:object) }
end
