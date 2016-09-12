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
# Name                                  | Type               | Attributes
# ------------------------------------- | ------------------ | ---------------------------
# **`created_at`**                      | `datetime`         | `not null`
# **`description`**                     | `text`             |
# **`filters`**                         | `jsonb`            | `not null`
# **`id`**                              | `integer`          | `not null, primary key`
# **`is_active`**                       | `boolean`          | `default(FALSE), not null`
# **`maximum_email_throttling_delay`**  | `integer`          |
# **`notification_type`**               | `string`           |
# **`only_authorized_recipients`**      | `boolean`          | `default(TRUE), not null`
# **`title`**                           | `string`           | `not null`
# **`triggering_action`**               | `string`           | `default("all"), not null`
# **`triggering_changes`**              | `jsonb`            | `not null`
# **`triggering_resource`**             | `string`           | `not null`
# **`updated_at`**                      | `datetime`         | `not null`
#
class NotificationProfile < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  serialize :triggering_changes, HashArraySerializer
  serialize :filters, HashArraySerializer

  has_and_belongs_to_many :users
  has_and_belongs_to_many :roles
  has_many :notifications

  # Returns a relations querying all recipient from the `users` and
  # the `roles` associations.
  #
  # @return [ActiveRecord::Relation] the relation specifying all users
  def recipients
    relation = User.joins(<<JOIN)
LEFT JOIN "notification_profiles_users" AS "np_u" ON "np_u"."user_id" = "users"."id"
LEFT JOIN "user_roles" AS "u_r" ON "u_r"."user_id" = "users"."id"
LEFT JOIN "notification_profiles_roles" AS "np_r" ON "np_r"."role_id" = "u_r"."role_id"
JOIN
    relation
      .select('DISTINCT("users"."id"), "users".*')
      .where('"np_u"."notification_profile_id" = ? OR "np_r"."notification_profile_id" = ?', id, id)
  end

  # Returns all `recipients` with `pending` and `sendable` notifications.
  #
  # Sendable notifications are notifications that either are not
  # throttled or thats throttling period has expired.
  #
  # The throttling period is the minimum of these three values:
  #
  # * ERICA.maximum_email_throttling_delay ([Integer] in seconds)
  # * notification_profile.maximum_email_throttling_delay = ([Integer] in seconds)
  # * user.email_throttling_delay = ([Integer] in seconds)
  def recipients_with_pending(options = {})
    relation = User
      .select('DISTINCT("users"."id"), "users".*')
      .joins(notifications: :notification_profile)
      .merge(Notification.of(self).pending)

    return relation unless options[:throttle]
    relation.merge(Notification.throttled(options[:throttle], joins: false))
  end

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
    relation = relation.where('triggering_resource = ?', record.class.to_s)
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
        triggers_matched &= !triggering.key?(:from) || (changes[attribute] && changes[attribute][0] == triggering[:from])
        triggers_matched &= !triggering.key?(:to) || (changes[attribute] && changes[attribute][1] == triggering[:to])
      end
      triggers_matched
    end.any?
  end

  # Apply filters on given `record`.
  #
  # @param [ActiveRecord::Base] record the record to match the filters against
  # @return [Boolean] whether the filter matched or not
  def filters_match?(record)
    return true if filters.empty?

    filters.map do |filter|
      filter_matched = true
      attr_filters = filter.delete(:attributes) || {}
      attr_filters.each_pair do |attr, val|
        filter_matched &= record.has_attribute?(attr) && record[attr] == val
      end
      filter.each_pair do |assoc, filters|
        next unless record._reflections.key?(assoc)
        if assoc =~ /s$/
          relation = record.send(assoc.to_sym)
          case filters
          when TrueClass, FalseClass
            filter_matched &= filters == relation.exists?
          when Hash
            filter_matched &= relation.where(filters).exists?
          end
        else
          related_record = record.send(assoc.to_sym)
          case filters
          when TrueClass, FalseClass
            filter_matched &= !filters == related_record.nil?
          when Hash
            filters.each_pair do |attr, val|
              filter_matched &= related_record.andand.has_attribute?(attr) && related_record[attr] == val
            end
          end
        end
      end
      filter_matched
    end.any?
  end

  def trigger(action, record)
    return false unless filters_match?(record)
    version = record.respond_to?(:versions) && record.versions.last
    recipients.map do |user|
      Notification.create(
        notification_profile: self,
        resource: record,
        user: user,
        version: version
      )
    end
  end

  # Creates a String in the form "attribute(from => to)" from the
  # `triggering_changes` Array. Array elements are logically disjunct
  # and all hash keys are logically conjunct.
  def triggering_changes_description
    return if triggering_changes.empty?
    conjs = triggering_changes.map do |conj|
      conj.map do |key, t|
        "#{key}(#{t.fetch(:from, '*any*')}=>#{t.fetch(:to, '*any*')})"
      end.join(' AND ')
    end
    conjs.map! { |conj| conj.include?('AND') ? "(#{conj})" : conj }
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
