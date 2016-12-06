class CenterDrop < EricaDrop # :nodoc:
  belongs_to(:study)
  has_many(:patients)

  desc 'The id of the study associated with this center.', :integer
  attribute(:study_id)

  desc 'The name of the center.', :string
  attribute(:name)

  desc 'Unique code for the center.', :string
  attribute(:code)

  desc 'The UNID for domino synchronization.', :string
  attribute(:domino_unid)

  desc 'Returns the full name in the format of `{{CODE}} - {{NAME}}`', :string
  def full_name
    object.full_name
  end
end
