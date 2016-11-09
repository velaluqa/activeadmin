class UserRoleDrop < Liquid::Rails::Drop # :nodoc:
  attributes(:id, :created_at, :updated_at)

  belongs_to(:user)
  belongs_to(:role)
  belongs_to(:scope_object)
  has_many(:permissions)
end
