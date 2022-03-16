class PublicKeyDrop < EricaDrop # :nodoc:
  belongs_to(:user)

  desc "Status of the key (active, deactivated)", :string
  attribute(:status)

  desc "Datetime this key was deactivated", :datetime
  attribute(:deactivated_at)

  desc "Datetime this key updated last", :datetime
  attribute(:updated_at)

  desc "Datetime this key created", :datetime
  attribute(:created_at)
end
