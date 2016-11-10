class CenterDrop < EricaDrop # :nodoc:
  attributes(
    :id,
    :study_id,
    :name,
    :code,
    :domino_unid,
    :created_at,
    :updated_at
  )

  belongs_to(:study)
  has_many(:patients)

  def full_name
    object.full_name
  end
end
