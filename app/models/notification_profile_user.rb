# ## Schema Information
#
# Table name: `notification_profile_users`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`id`**                       | `integer`          | `not null, primary key`
# **`notification_profile_id`**  | `integer`          | `not null`
# **`user_id`**                  | `integer`          | `not null`
#
# ### Indexes
#
# * `index_notification_profile_users_join_table_index` (_unique_):
#     * **`notification_profile_id`**
#     * **`user_id`**
# * `index_notification_profile_users_on_user_id`:
#     * **`user_id`**
#

class NotificationProfileUser < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  belongs_to :notification_profile
  belongs_to :user
end
