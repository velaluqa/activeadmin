# ## Schema Information
#
# Table name: `user_roles`
#
# ### Columns
#
# Name                     | Type               | Attributes
# ------------------------ | ------------------ | ---------------------------
# **`created_at`**         | `datetime`         | `not null`
# **`id`**                 | `integer`          | `not null, primary key`
# **`role_id`**            | `integer`          | `not null`
# **`scope_object_id`**    | `integer`          |
# **`scope_object_type`**  | `string`           |
# **`updated_at`**         | `datetime`         | `not null`
# **`user_id`**            | `integer`          | `not null`
#
# ### Indexes
#
# * `index_user_roles_on_role_id`:
#     * **`role_id`**
# * `index_user_roles_on_scope_object_type_and_scope_object_id`:
#     * **`scope_object_type`**
#     * **`scope_object_id`**
# * `index_user_roles_on_user_id`:
#     * **`user_id`**
#
class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :scope_object, polymorphic: true
  has_many :permissions, through: :role

  validates :role, presence: true
  validates :role, uniqueness: { scope: [:user, :scope_object], message: 'User already has this role and scope combination' }

  attr_accessible :user, :role, :scope_object
  # Needed for ActiveAdmin nested associations:
  attr_accessible :role_id, :scope_object_identifier

  scope :with_scope, lambda { |*scope|
    return where.not(scope_object_id: nil) unless scope.first
    where(scope_object_id: scope.first.id, scope_object_type: scope.first.to_s)
  }
  scope :without_scope, -> { where(scope_object_id: nil) }

  # Returns accessible scope_object identifiers for ActiveAdmin form
  # select fields.
  #
  # @return [Array<[String, String]>] The identifier in the form of
  #   [[title, identifier]].
  def self.accessible_scope_object_identifiers(ability)
    Study.accessible_by(ability).pluck(:name, "CONCAT('study_', studies.id)")
  end

  # A helper to allow polymorphic associations with ActiveAdmin.
  #
  # @return [String] the polymorphic identifier for the `scope_object`
  def scope_object_identifier
    return 'systemwide' unless scope_object
    "#{scope_object_type.to_s.underscore}_#{scope_object_id}"
  end

  # A helper to set the `scope_object` via ActiveAdmin associations.
  #
  # @param [String] identifier The identifier in the form of
  #   `<scope_object_type>_<scope_object_id>` to associate from
  #   ActiveAdmin form.
  def scope_object_identifier=(identifier)
    return self.scope_object = nil if identifier == 'systemwide'
    match = identifier.match(/^(?<scope_object_type>.*)_(?<scope_object_id>\d+)$/)
    return unless match
    self.scope_object_id = match[:scope_object_id].to_i
    self.scope_object_type = match[:scope_object_type].classify
  end
end
