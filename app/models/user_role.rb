class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :scope_object, polymorphic: true
  has_many :permissions, through: :role

  scope :with_scope, lambda { |*scope|
    return where.not(scope_object_id: nil) unless scope.first
    where(scope_object_id: scope.first.id, scope_object_type: scope.first.to_s)
  }
  scope :without_scope, -> { where(scope_object_id: nil) }
end
