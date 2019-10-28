# ## Schema Information
#
# Table name: `notification_profile_roles`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`id`**                       | `integer`          | `not null, primary key`
# **`notification_profile_id`**  | `integer`          | `not null`
# **`role_id`**                  | `integer`          | `not null`
#
# ### Indexes
#
# * `index_notification_profile_roles_join_table_index` (_unique_):
#     * **`notification_profile_id`**
#     * **`role_id`**
# * `index_notification_profile_roles_on_role_id`:
#     * **`role_id`**
#
class NotificationProfileRole < ApplicationRecord
  has_paper_trail class_name: 'Version'

  belongs_to :notification_profile
  belongs_to :role
end
