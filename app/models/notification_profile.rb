require 'serializers/hash_array_serializer'

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
  serialize :triggering_changes, HashArraySerializer
  serialize :filters, HashArraySerializer

  # For convenience we convert all triggering_changes hashes to
  # `HashWithIndifferentAccess`, allowing us to access { 'a' => 1 }
  # with either `:a` and `'a'`.
  def triggering_changes
    read_attribute(:triggering_changes).map(&:with_indifferent_access)
  end

  # For convenience we convert all filter hashes to
  # `HashWithIndifferentAccess`, allowing us to access { 'a' => 1 }
  # with either `:a` and `'a'`.
  def filters
    read_attribute(:filters).map(&:with_indifferent_access)
  end

  # Returns all profiles that match the given action for given
  # resource. The resource may have changes, which are used to match
  # against a profiles `triggering_changes`.
  #
  # @param [Symbol] action the specific action that was performed
  # @param [ActiveRecord::Base] record the record the action was performed on
  #
  # @return [Array] an array of matched `NotificationProfile` instances
  def self.triggered_by(action, record)
    relation = where(%(triggering_action = 'all' OR triggering_action = ?), action.to_s)
    relation.where('triggering_resource = ?', record.class.to_s)
    relation.to_a.keep_if do |profile|
      profile.triggering_changes?(record)
    end
  end

  # Matches the `changes` of given record against the `triggering_changes`.
  #
  # @param [ActiveRecord::Base] the record with changes
  #
  # @return [Boolean] whether the record triggers of not
  def triggering_changes?(record)
    return true if triggering_changes.empty?
    changes = record.changes.with_indifferent_access
    triggering_changes.map do |conj_changes|
      triggers_matched = true
      conj_changes.each_pair do |attribute, triggering|
        triggers_matched &= false if triggering.key?(:from) && (!changes[attribute] || changes[attribute][0] != triggering[:from])
        triggers_matched &= false if triggering.key?(:to) && (!changes[attribute] || changes[attribute][1] != triggering[:to])
      end
      triggers_matched
    end.any?
  end

  def filter_matches?(record)

  end

  def trigger(action, resource)

  end

  # Creates a String in the form "attribute(from => to)" from the
  # `triggering_changes` Array. Array elements are logically disjunct
  # and all hash keys are logically conjunct.
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
