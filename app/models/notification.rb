# # Notification
#
#
# ## Schema Information
#
# Table name: `notifications`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`created_at`**               | `datetime`         |
# **`email_sent_at`**            | `datetime`         |
# **`id`**                       | `integer`          | `not null, primary key`
# **`marked_seen_at`**           | `datetime`         |
# **`notification_profile_id`**  | `integer`          | `not null`
# **`resource_id`**              | `integer`          | `not null`
# **`resource_type`**            | `string`           | `not null`
# **`updated_at`**               | `datetime`         |
# **`user_id`**                  | `integer`          | `not null`
# **`version_id`**               | `integer`          |
#
# ### Indexes
#
# * `index_notifications_on_resource_type_and_resource_id`:
#     * **`resource_type`**
#     * **`resource_id`**
# * `index_notifications_on_user_id`:
#     * **`user_id`**
# * `index_notifications_on_version_id`:
#     * **`version_id`**
#
class Notification < ActiveRecord::Base
  belongs_to :notification_profile
  belongs_to :user
  belongs_to :version
  belongs_to :resource, polymorphic: true
end
