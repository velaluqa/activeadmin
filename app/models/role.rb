##
# A role is a simple entity that defines a set of permissions.
#
# One `User` can have multiple `Roles` through `UserRoles`.
class Role < ActiveRecord::Base
  has_paper_trail

  attr_accessible :title

  has_many :user_roles
  has_many :users, through: :user_roles

  has_many :permissions
end
