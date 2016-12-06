class RoleDrop < EricaDrop # :nodoc:
  desc 'Through UserRole a role is associated with many users.'
  has_many(:user_roles)

  desc 'Through UserRole a role is associated with many users.'
  has_many(:users)

  desc 'A role grants specific permissions.'
  has_many(:permissions)

  desc 'Notification profiles can set all users of a role as recipients.'
  has_many(:notification_profiles)

  desc 'Title of the role.', :string
  attribute(:title)
end
