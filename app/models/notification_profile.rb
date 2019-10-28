# coding: utf-8

require 'serializers/hash_array_serializer'
require 'serializers/string_array_serializer'

require 'notification_observable/filter'
require 'notification_observable/filter/schema'

# Notification Profiles describe which actions within the ERICA system
# trigger notifications.
#
# ## Trigger
#
# A trigger is defined by two attributes:
#
# * `[Array<String>] triggering_actions` — The CRUD actions performed on that resource, that trigger the `NotificationProfile`. Typically this means the ActiveRecord action (e.g. `create`, `ApplicationRecord
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
p #
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
# **`email_template_id`**               | `integer`          | `not null`
# **`filter_triggering_user`**          | `string`           | `default("exclude"), not null`
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
  TRIGGERING_RESOURCES = %w[
    Study
    Center
    Patient
    ImageSeries
    Image
    Visit
    RequiredSeries
  ].freeze

  has_paper_trail class_name: 'Version'

  serialize :triggering_actions, StringArraySerializer
  serialize :filters, HashArraySerializer

  has_many :notification_profile_users
  has_many :users, through: :notification_profile_users, dependent: :destroy
  has_many :notification_profile_roles
  has_many :roles, through: :notification_profile_roles, dependent: :destroy

  has_many :notifications

  belongs_to :email_template

  validates :title, presence: true
  validates :triggering_actions, presence: true
  validates :triggering_resource, presence: true
  # TODO: Add inclusion: { in: -> (a) { NotificationProfile::TRIGGERING_RESOURCES } }
  # Currently a LOT of tests break, when adding inclusion, because
  # tests are adding a TestModel which is not allowed...
  validates :filters, json: { schema: :filters_schema, message: ->(messages) { messages } }, if: :triggering_resource_class
  validates :maximum_email_throttling_delay, inclusion: { in: Email.allowed_throttling_delays.values }, if: :maximum_email_throttling_delay
  validates :filter_triggering_user, inclusion: { in: %w[exclude include only] }
  validate :validate_triggering_actions
  validates :email_template, presence: true
  validate :validate_email_template_type

  scope :enabled, -> { where(is_enabled: true) }

  # Returns all distinct recipients from `users` and `roles` associations.
  #
  # If no `users` or `roles` are available, all available users are presumed recipients.
  #
  # @return [ActiveRecord::Relation<User>] the relation specifying all users
  def recipients
    return User.all if all_users?
    relation = User.joins(<<JOIN.strip_heredoc)
      LEFT JOIN "notification_profile_users" AS "np_u" ON "np_u"."user_id" = "users"."id"
      LEFT JOIN "user_roles" AS "u_r" ON "u_r"."user_id" = "users"."id"
      LEFT JOIN "notification_profile_roles" AS "np_r" ON "np_r"."role_id" = "u_r"."role_id"
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
  def self.triggered_by(action, resource_type, resource, changes = {})
    relation = enabled.where(
      'triggering_actions ? :action AND triggering_resource = :resource',
      action: action,
      resource: resource_type
    )
    relation.to_a.keep_if do |profile|
      profile.filter.match?(resource, changes)
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
  def trigger(version)
    recipient_candidates(version.triggering_user).map do |user|
      next if only_authorized_recipients && !user.can?(:read, version.item || version.reify)
      Notification.create!(
        notification_profile: self,
        triggering_action: version.event,
        resource: version.item,
        user: user,
        version: version
      )
    end.compact
  end

  # TODO: Extract triggering profiles into separate Operation object.
  #
  # Gives a filtered recipients relation for given triggering_user.
  def recipient_candidates(triggering_user)
    return recipients if triggering_user.blank?
    case filter_triggering_user
    when 'only' then recipients.where(id: triggering_user.id)
    when 'exclude' then recipients.where.not(id: triggering_user.id)
    when 'include' then recipients
    end
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

  # Getter for ActiveAdmin form field that holds recipient users and
  # roles.
  def recipient_refs
    refs = []
    users.each { |user| refs.push("User_#{user.id}") }
    roles.each { |role| refs.push("Role_#{role.id}") }
    refs
  end

  # Setter for ActiveAdmin form field that holds recipient users and
  # roles.
  def recipient_refs=(refs)
    if refs.include?('all')
      self.users = []
      self.roles = []
    else
      self.users = refs.select { |ref| ref.include?('User') }.map { |ref| User.find_by_ref(ref) }
      self.roles = refs.select { |ref| ref.include?('Role') }.map { |ref| Role.find_by_ref(ref) }
    end
  end

  # Collection for ActiveAdmin to use as preloaded set of options for
  # current values.
  def preload_recipient_refs
    coll = []
    users.each { |user| coll << ["User: #{user.name}", "User_#{user.id}"] }
    roles.each { |role| coll << ["Role: #{role.title}", "Role_#{role.id}"] }
    coll
  end

  def all_users?
    users.empty? && roles.empty?
  end

  protected

  def validate_triggering_actions
    return errors.add(:triggering_actions, :not_array) unless triggering_actions.is_a?(Array)
    if triggering_actions - %w[create update destroy] != []
      errors.add(:triggering_actions, :invalid)
    end
  end

  def validate_email_template_type
    return if email_template.blank?
    return if email_template.email_type == 'NotificationProfile'
    errors.add(:email_template, :invalid)
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
