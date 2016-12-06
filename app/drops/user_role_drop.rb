class UserRoleDrop < EricaDrop # :nodoc:
  belongs_to(:user)
  belongs_to(:role)
  belongs_to(:scope_object)
  has_many(:permissions)
end
