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

  def triggering_changes_description
    return if triggering_changes.empty?
    conjs = triggering_changes.map do |conj|
      conj.map do |key, triggering|
        from = triggering.key?(:from) ? triggering[:from].inspect : '*any*'
        to = triggering.key?(:to) ? triggering[:to].inspect : '*any*'
        "#{key}(#{from}=>#{to})"
      end.join(' AND ')
    end
    conjs.map! do |conj|
      if conj.include?('AND')
        "(#{conj})"
      else
        conj
      end
    end
    conjs.join(' OR ')
  end

  def to_s
    changes = triggering_changes_description
    changes = ", #{changes}" if changes
    "NotificationProfile[#{id}, #{triggering_action}, #{triggering_resource}#{changes}]"
  end

  def inspect
    changes = triggering_changes_description
    changes = ", #{changes}" if changes
    "NotificationProfile[#{id}, #{triggering_action}, #{triggering_resource}#{changes}]"
  end
end
