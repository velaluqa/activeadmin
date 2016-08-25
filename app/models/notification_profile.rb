# Notification Profiles describe which actions within the ERICA system
# trigger notifications.
#
# ## Schema Information
#
# Table name: `notification_profiles`
#
# ### Columns
#
# Name                              | Type               | Attributes
# --------------------------------- | ------------------ | ---------------------------
# **`created_at`**                  | `datetime`         | `not null`
# **`description`**                 | `text`             |
# **`filters`**                     | `jsonb`            | `not null`
# **`id`**                          | `integer`          | `not null, primary key`
# **`is_active`**                   | `boolean`          | `default(FALSE), not null`
# **`notification_type`**           | `string`           |
# **`only_authorized_recipients`**  | `boolean`          | `default(TRUE), not null`
# **`title`**                       | `string`           | `not null`
# **`triggering_action`**           | `string`           | `default("all"), not null`
# **`triggering_changes`**          | `jsonb`            | `not null`
# **`triggering_resource`**         | `string`           | `not null`
# **`updated_at`**                  | `datetime`         | `not null`
#
class NotificationProfile < ActiveRecord::Base
  def self.triggered_by(action, record, changes)

  def filter_matches?(record)

  end

  def trigger(action, resource)

  end
end
