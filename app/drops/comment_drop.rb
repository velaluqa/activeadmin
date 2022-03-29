class CommentDrop < EricaDrop # :nodoc:
  belongs_to(:resource)
  belongs_to(:user)

  desc 'Text written by the user', :string
  attribute(:body)

  desc 'Update datetime', :datetime
  attribute(:updated_at)

  desc 'Creation date', :datetime
  attribute(:created_at)
end
