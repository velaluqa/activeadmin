class FormDefinitionDrop < EricaDrop # :nodoc:
  has_many(:form_answers)

  desc 'Name of the form', :string
  attribute(:name)

  desc 'Description of the form', :string
  attribute(:description)
end
