class RoleDrop < EricaDrop # :nodoc:
  attributes(
    :id,
    :title,
    :created_at,
    :updated_at
  )

  has_many(:user_roles)
  has_many(:users)
  has_many(:permissions)
  has_many(:notification_profiles)
end
