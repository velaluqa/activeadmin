class PatientDrop < EricaDrop # :nodoc:
  belongs_to(:center)
  has_many(:visits)

  desc 'A patient is imaged in one or more image series.'
  has_many(:image_series)

  desc 'The individual subject id of the patient.', :string
  attribute(:subject_id)

  desc 'The folder with the images of the patient', :string
  attribute(:images_folder)

  desc 'The export history object.', :json
  attribute(:export_history)

  desc 'Extra data for the patient.', :json
  attribute(:data)

  desc 'UNID for the domino sync.', :string
  attribute(:domino_unid)

  desc 'Patient number within domino.', :string
  delegate(:domino_patient_number, to: :object)
end
