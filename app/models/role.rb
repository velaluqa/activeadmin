##
# A role is a simple entity that defines a set of permissions.
#
# One `User` can have multiple `Roles` through `UserRoles`.
#
# ## Schema Information
#
# Table name: `roles`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`created_at`**  | `datetime`         |
# **`id`**          | `integer`          | `not null, primary key`
# **`title`**       | `string`           | `not null`
# **`updated_at`**  | `datetime`         |
#
class Role < ActiveRecord::Base
  has_paper_trail

  attr_accessible :title, :abilities

  has_many :user_roles
  has_many :users, through: :user_roles

  has_many :permissions, dependent: :destroy

  validates :title, presence: true, uniqueness: true

  def allows?(activities, subject)
    subject_string = subject.to_s.underscore
    Array[activities].flatten.any? do |activity|
      ability?("#{activity}_#{subject_string}")
    end
  end
  alias allows_any? allows?

  def ability?(ability)
    abilities.include?(ability)
  end

  def abilities
    permissions.map(&:ability)
  end

  def abilities=(abilities)
    new_permissions = []
    permissions.each do |permission|
      next unless abilities.include?(permission.ability)
      new_permissions << permission
    end
    abilities.each do |ability|
      next if ability?(ability)
      new_permissions << Permission.from_ability(ability)
    end
    self.permissions = new_permissions
  end
end
