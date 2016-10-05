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
# **`triggering_resource`**             | `string`           | `not null`
# **`updated_at`**                      | `datetime`         | `not null`
#
class NotificationProfile < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  serialize :filters, HashArraySerializer

  has_and_belongs_to_many :users
  has_and_belongs_to_many :roles
  has_many :notifications

  validates :title, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  validates :triggering_action, presence: true, inclusion: { in: %w(all create update destroy) }
  validates :triggering_resource, presence: true
  validates :filters, json: { schema: :filters_schema, message: -> (messages) { messages } }, if: :triggering_resource_class
  validates :maximum_email_throttling_delay, inclusion: { in: Email.allowed_throttling_delays.values }, if: :maximum_email_throttling_delay

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

  # Returns all profiles that match the given action for given
  # resource. The resource may have changes, which are used to match
  # against a profiles `triggering_changes`.
  #
  # @param [Symbol] action the specific action that was performed
  # @param [ActiveRecord::Base] record the record the action was performed on
  #
  # @return [Array] an array of matched `NotificationProfile` instances
  def self.triggered_by(action, record, changes = {})
    relation = where(%(triggering_action = 'all' OR triggering_action = ?), action.to_s)
    relation = relation.where('triggering_resource = ?', record.class.to_s)
    relation.to_a.keep_if do |profile|
      profile.filter.match?(record, changes)
    end
  end

  def filter
    @filter ||= NotificationObservable::Filter.new(filters)
  end

  def trigger(action, record)
    version = record.try(:versions).andand.last
    recipients.map do |user|
      next if user == ::PaperTrail.whodunnit
      Notification.create(
        notification_profile: self,
        resource: record,
        user: user,
        version: version
      )
    end.compact
  end

  def filters_json=(str)
    self.filters = JSON.parse(str)
  end

  def filters_json
    filters.to_json
  end

  def to_s
    props = [id, triggering_action, triggering_resource, filter.to_s]
    "NotificationProfile[#{props.compact.join(', ')}]"
  end

  protected

  def filters_schema
    NotificationObservable::Filter::Schema.new(triggering_resource_class).schema.deep_stringify_keys
  end

  def triggering_resource_class
    triggering_resource.constantize
  rescue
    nil
  end
end
