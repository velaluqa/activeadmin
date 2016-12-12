class PermissionDrop < EricaDrop # :nodoc:
  belongs_to(:role)
  has_many(:users)

  desc 'Activity granted by this permission.', :string
  attribute(:activity)

  desc 'Subject the activity is granted for.', :stringx
  attribute(:subject)

  desc 'Concatenation of activity and subject in the form of `{{ACTIVITY}}_{{SUBJECT}}`.', :string
  delegate(:ability, to: :object)
end
