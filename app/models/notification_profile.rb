# coding: utf-8
require 'serializers/hash_array_serializer'
require 'serializers/string_array_serializer'

# Notification Profiles describe which actions within the ERICA system
# trigger notifications.
#
# ## Trigger
#
# A trigger is defined by two attributes:
#
# * `[Array<String>] triggering_actions` — The CRUD actions performed on that resource, that trigger the `NotificationProfile`. Typically this means the ActiveRecord action (e.g. `create`, `update` or `destroy`).
# * `[String] triggering_resource` — The resource which is triggering this profile. Usually this is the model name within the ERICA system.
#
# ## Filter
#
# When an action on a resource triggers this profile, this resource can be filtered.
#
# ### Filtering Attribute Values
#
# The triggering resource filtered by attribute value.
#
# Example: A NotificationProfile with triggering action ~create~ and
# triggering resource ~Visit~, can be filtered by attribute value match so
# that only for created visits with ~state != :incomplete_queried~
# triggers a notification.
#
# ### Filtering Changes
#
# The triggering resource is providing information about the changes
# performed by the triggering action (e.g. ~update~ in attributes).
#
# Example: A NotificationProfile with triggering action ~update~ and
# triggering resource ~ImageSeries~ can be filtered so that only a change
# of the state from ~:importing~ to ~:imported~ triggers a notification.
#
# ### Filtering Relations
#
# The triggering resource can be filtered by relations in two ways:
#
# * Existence — e.g. an image series that has been assigned to a
#      visit should have a related visit.
# * Related Model Attribute Match — e.g. an image series that has been
#      assigned to a visit with a specific attribute value.
#
# ## Recipients
#
# Recipients can be defined via referencing users directly or via
# referencing user roles.
#
# Each profile has ~users~ and ~roles~. Furthermore you can configure
# the profile so that notifications are only created for those
# recipients, that are also authorized to access the triggering
# resource. For that, see the ~only_authorized_users~ attribute.
#
# ## Throttling
#
# We do not want the user to be spammed by e-mails for each and every
# action done in the ERICA system. Thus sending e-mails can be
# throttled on a per-profile basis.
#
# ERICA is running recurring jobs for hourly, daily, weekly, monthly,
# semesterly, quarterly and yearly throttling. ERICA allows to
# configure the system-wide `maximum_email_throttling_delay` (default:
# `monthly`).
#
# A user can set an ~email_throttling_delay~ which is lower than the
# system-wide maximum.
#
# This email throttling delay can be overridden by
# NotificationProfile´s `maximum_email_throttling__delay`. This way
# you can manage priority among your NotificationProfiles.
#
# For example you could set a profiles maximum throttling delay to
# `instantly`, which would mean, that the emails are sent as soon as the
# Notification is created.
#
# If you had set the maximum throttling delay to `hourly` the
# notifications would be sent each hour instead.
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
# **`is_enabled`**                      | `boolean`          | `default(FALSE), not null`
# **`maximum_email_throttling_delay`**  | `integer`          |
# **`notification_type`**               | `string`           |
# **`only_authorized_recipients`**      | `boolean`          | `default(TRUE), not null`
# **`title`**                           | `string`           | `not null`
# **`triggering_actions`**              | `jsonb`            | `not null`
# **`triggering_resource`**             | `string`           | `not null`
# **`updated_at`**                      | `datetime`         | `not null`
#
class NotificationProfile < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  serialize :triggering_actions, StringArraySerializer
  serialize :filters, HashArraySerializer

  has_and_belongs_to_many :users
  has_and_belongs_to_many :roles
  has_many :notifications

  validates :title, presence: true
  validates :is_enabled, inclusion: { in: [true, false] }
  validates :triggering_actions, presence: true
  validates :triggering_resource, presence: true
  validates :filters, json: { schema: :filters_schema, message: -> (messages) { messages } }, if: :triggering_resource_class
  validates :maximum_email_throttling_delay, inclusion: { in: Email.allowed_throttling_delays.values }, if: :maximum_email_throttling_delay
  validate :validate_triggering_actions

  scope :enabled, -> { where(is_enabled: true) }

  # Returns all distinct recipients from `users` and `roles` associations.
  #
  # @return [ActiveRecord::Relation<User>] the relation specifying all users
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

  # Returns all `recipients` with `pending` and `sendable`
  # notifications, optionally by throttling delay `:throttle`.
  #
  # Sendable notifications are notifications that either are not
  # throttled or thats throttling period has expired.
  #
  # The throttling period is the minimum of these three values:
  #
  # * ERICA.maximum_email_throttling_delay ([Integer] in seconds)
  # * notification_profile.maximum_email_throttling_delay = ([Integer] in seconds)
  # * user.email_throttling_delay = ([Integer] in seconds)
  #
  # @option options [Fixnum] :throttle throttling delay in seconds
  #
  # @return [ActiveRecord::Relation<User>] users with pending notifications
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
  # against a profiles `filters`.
  #
  # @param [Symbol] action the specific action that was performed
  # @param [ActiveRecord::Base] record the record the action was performed on
  # @param [Hash] changes format of `{ attribute: [old, new] }`
  #
  # @return [Array] an array of matched `NotificationProfile` instances
  def self.triggered_by(action, record, changes = {})
    relation = enabled.where(
      'triggering_actions ? :action AND triggering_resource = :resource',
      action: action,
      resource: record.class.to_s
    )
    relation.to_a.keep_if do |profile|
      profile.filter.match?(record, changes)
    end
  end

  # The instatiated `NotificationObservable::Filter` for records
  # `filter` JSON.
  def filter
    @filter ||= NotificationObservable::Filter.new(filters)
  end

  # Creates `Notification` records for all respective recipients.
  #
  # If the `only_authorized_recipients` flag is set to `true`, only
  # users that are authorized to `:read` the given resource will get a
  # notification.
  #
  # @param [String, Symbol] action The action triggering this profile.
  # @param [ActiveRecord::Base] record The record the action was
  #   performed on.
  # @return [Array<Notification>] array of created `Notification`
  #   records.
  def trigger(action, record)
    version = record.try(:versions).andand.last
    recipients.map do |user|
      next if user == ::PaperTrail.whodunnit
      next if only_authorized_recipients && !user.can?(:read, record)
      Notification.create(
        notification_profile: self,
        resource: record,
        user: user,
        version: version
      )
    end.compact
  end

  # Helper method used by ActiveAdmin to set the filters from JSON
  # string.
  #
  # @param [String] str The filters as JSON String.
  def filters_json=(str)
    self.filters = JSON.parse(str)
  end

  # Helper method used by ActiveAdmin form to get the filters as JSON
  # string.
  #
  # @return [String] The filters as JSON String.
  def filters_json
    filters.to_json
  end

  def to_s
    props = [id, triggering_action, triggering_resource, filter.to_s]
    "NotificationProfile[#{props.compact.join(', ')}]"
  end

  # Reject blank strings when setting `triggering_actions`.
  #
  # Formtastic is sending an array with a blank string to ensure that
  # we can reset the array via the form. Since we only allow the
  # default CRUD actions `create`, `update` and `destroy`, we have to
  # remove the blank string for the `triggering_actions` to be valid.
  #
  # @param [Array<String>] ary The triggering actions to set.
  def triggering_actions=(ary)
    write_attribute(:triggering_actions, Array(ary).reject(&:blank?))
  end

  protected

  def validate_triggering_actions
    return errors.add(:triggering_actions, :not_array) unless triggering_actions.is_a?(Array)
    if triggering_actions - %w(create update destroy) != []
      errors.add(:triggering_actions, :invalid)
    end
  end

  def filters_schema
    NotificationObservable::Filter::Schema.new(triggering_resource_class).schema.deep_stringify_keys
  end

  def triggering_resource_class
    triggering_resource.constantize
  rescue
    nil
  end
end
