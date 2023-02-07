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

FactoryBot.define do
  factory :user_role do
    transient do
      with_permissions do
        {}
      end
    end

    user
    role

    # Scope is nil by default, which means this user_roles
    # role-permissions will be granted system-wide.
    scope_object { nil }

    before(:create) do |user_role, evaluator|
      unless user_role.role
        user_role.role =
          create(:role, with_permissions: evaluator.with_permissions)
      end
    end
  end
end
