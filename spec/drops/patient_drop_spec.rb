describe PatientDrop do
  before(:each) do
    allow(subject.send(:object)).to receive(:domino_patient_number)
  end

  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:subject_id) }
  it { is_expected.to have_attribute(:images_folder) }
  it { is_expected.to have_attribute(:export_history) }
  it { is_expected.to have_attribute(:data) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }
  it { is_expected.to have_attribute(:domino_unid) }

  it { is_expected.to belongs_to(:center) }
  it { is_expected.to have_many(:visits) }
  it { is_expected.to have_many(:image_series) }

  it { is_expected.to delegate(:domino_patient_number).to(:object) }
end
