class FormAnswerDrop < EricaDrop # :nodoc:
  belongs_to(:form_session)
  belongs_to(:form_definition)
  belongs_to(:user)
  belongs_to(:public_key)

  desc 'Status of the form answer', :string
  attribute(:status)

  desc 'Status of the signature', :string
  attribute(:signature_status)

  desc 'Answers given by user', :json
  attribute(:answers)

  desc 'Sequence number', :integer
  attribute(:sequence_number)

  desc 'Date of signage and submission', :datetime
  attribute(:submitted_at)

  desc 'Update datetime', :datetime
  attribute(:updated_at)

  desc 'Creation date', :datetime
  attribute(:created_at)
end
