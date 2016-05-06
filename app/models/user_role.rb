# ## Schema Information
#
# Table name: `user_roles`
#
# ### Columns
#
# Name                     | Type               | Attributes
# ------------------------ | ------------------ | ---------------------------
# **`created_at`**         | `datetime`         | `not null`
# **`id`**                 | `integer`          | `not null, primary key`
# **`role_id`**            | `integer`          | `not null`
# **`scope_object_id`**    | `integer`          |
# **`scope_object_type`**  | `string`           |
# **`updated_at`**         | `datetime`         | `not null`
# **`user_id`**            | `integer`          | `not null`
#
# ### Indexes
#
# * `index_user_roles_on_role_id`:
#     * **`role_id`**
# * `index_user_roles_on_scope_object_type_and_scope_object_id`:
#     * **`scope_object_type`**
#     * **`scope_object_id`**
# * `index_user_roles_on_user_id`:
#     * **`user_id`**
#
class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :scope_object, polymorphic: true
  has_many :permissions, through: :role

  scope :with_scope, lambda { |*scope|
    return where.not(scope_object_id: nil) unless scope.first
    where(scope_object_id: scope.first.id, scope_object_type: scope.first.to_s)
  }
  scope :without_scope, -> { where(scope_object_id: nil) }
end
