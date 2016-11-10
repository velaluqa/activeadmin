class PatientDrop < EricaDrop # :nodoc:
  attributes(
    :id,
    :subject_id,
    :images_folder,
    :export_history,
    :data,
    :created_at,
    :updated_at,
    :domino_unid
  )

  belongs_to(:center)
  has_many(:visits)
  has_many(:image_series)

  delegate(:domino_patient_number, to: :object)
end
