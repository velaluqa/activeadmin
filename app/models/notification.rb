# # Notification
#
# Notifications are simple relations describing which resource caused
# a notification profile to trigger an e-mail being sent as notification.
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
# **`triggering_action`**        | `string`           | `not null`
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
  has_paper_trail(
    class_name: 'Version',
    version: :paper_trail_version,
    versions: :paper_trail_versions
  )

  after_create :send_instant_notification_email

  belongs_to :notification_profile
  belongs_to :user
  belongs_to :version
  belongs_to :resource, polymorphic: true

  validates :user, presence: true
  validates :notification_profile, presence: true
  validates :resource, presence: true

  # All notifications that have not yet been sent.
  scope :pending, -> { where(email_sent_at: nil) }

  # All notifications for given user.
  #
  # @param [User,Integer] user The user to filter by.
  scope :for, -> (user) { where(user: user) }

  # All notifications belonging to given profile.
  #
  # @param [NotificationProfile,Integer] profile The profile to filter by.
  scope :of, -> (profile) { where(notification_profile: profile) }

  # All notifications that are throttled via given throttling delay.
  scope :throttled, -> (throttle, options = { joins: true }) do
    throttle = Email.ensure_throttling_delay(throttle)
    (options[:joins] ? joins(:notification_profile, :user) : all)
      .where('least(?, notification_profiles.maximum_email_throttling_delay, users.email_throttling_delay) = ?',
             ERICA.maximum_email_throttling_delay, throttle)
  end

  # Returns the delay to which this notification is throttled.
  # This throttling delay is limited by the system-wide and
  # notification profiles `maximum_email_throttling_delay`.
  #
  # @return [Integer] the throttling delay in seconds
  def email_throttling_delay
    [
      ERICA.maximum_email_throttling_delay,
      notification_profile.maximum_email_throttling_delay,
      user.email_throttling_delay
    ].compact.min
  end

  # Whether a notification is throttled or not.
  #
  # @return [Boolean] true if throttled
  def throttled?
    email_throttling_delay > 0
  end

  protected

  def send_instant_notification_email
    return if throttled?
    SendInstantNotificationEmail.perform_async(id)
  end
end
