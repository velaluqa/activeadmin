# ## Schema Information
#
# Table name: `permissions`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`activity`**    | `string`           | `not null`
# **`created_at`**  | `datetime`         | `not null`
# **`id`**          | `integer`          | `not null, primary key`
# **`role_id`**     | `integer`          | `not null`
# **`subject`**     | `string`           | `not null`
# **`updated_at`**  | `datetime`         | `not null`
#
# ### Indexes
#
# * `index_permissions_on_activity`:
#     * **`activity`**
# * `index_permissions_on_role_id`:
#     * **`role_id`**
# * `index_permissions_on_subject`:
#     * **`subject`**
#
class Permission < ActiveRecord::Base
  include NotificationObservable

  ABILITY_REGEX = /^(.+)_(#{Ability::ACTIVITIES.keys.map{|subject| subject.to_s.underscore}.join('|')})$/

  belongs_to :role
  has_many :users, through: :roles

  # Initializes a new instance from a given ability string.
  #
  # @param [String] ability The ability in the form of
  #   '[activity]_[subject]'
  #
  # @return [Permission] a newly initialized permission object
  def self.from_ability(ability)
    if (match = ABILITY_REGEX.match(ability))
      Permission.new(
        activity: match[1],
        subject: match[2].classify.constantize
      )
    else
      raise "Unable to match ability string #{ability}"
    end
  end

  # Get the activity as symbol.
  #
  # @return [Symbol] The activity as symbol
  def activity
    read_attribute(:activity).to_sym
  end

  # Set the activity as string.
  #
  # @param [Symbol, String] activity A permissible activity (defaults
  #   are `:read`, `:update`, `:create`, `:destroy`)
  def activity=(activity)
    write_attribute(:activity, activity.to_s)
  end

  # Get the subject constant.
  #
  # @return [Class<ActiveRecord::Base>] The subject for this permission
  def subject
    read_attribute(:subject).constantize
  end

  # Set the subject as string.
  #
  # @param [Class<ActiveRecord::Base>, String] subject A cancan subject
  def subject=(subject)
    write_attribute(:subject, subject.to_s)
  end

  # Get the ability string.
  #
  # @return [String] The ability in the form of
  #   '[activity]_[subject]'
  def ability
    "#{activity}_#{subject.to_s.underscore}"
  end

  def to_s
    "Permission[#{activity} #{subject}]"
  end
end
