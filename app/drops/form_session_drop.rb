class FormSessionDrop < EricaDrop # :nodoc:
  has_many :form_answers

  desc 'Name of the session', :string
  attribute(:name)

  desc 'Description of the session', :string
  attribute(:description)
end
