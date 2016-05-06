class Ability
  include CanCan::Ability

  attr_reader :current_user

  ACTIVITIES = {
    Study  => %i(manage read update create destroy),
    Center => %i(manage read update create destroy),
    Patient => %i(manage read update create destroy),
    ImageSeries => %i(manage read update create destroy),
    Image => %i(manage read update create destroy),
    User => %i(manage read update create destroy),
    PublicKey => %i(manage read update create destroy),
    Role => %i(manage read update create destroy),
    Visit => %i(manage read update create destroy)
  }.freeze

  def initialize(current_user)
    @current_user = current_user

    can :read, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'

    if current_user.is_root_user?
      can :manage, ACTIVITIES.keys
    else
      define_system_wide_abilities
      define_scopable_abilities
      basic_abilities
    end
  end

  private

  ##
  # System-wide abilities allow activities on any instance of a given
  # subject type. For example you can grant permissions to `:read` any
  # `Study`.
  def define_system_wide_abilities
    current_user.user_roles.without_scope.each do |role|
      role.permissions.each do |permission|
        can(permission.activity, permission.subject)
      end
    end
  end

  ##
  # Scoped abilities allow activities on any record filtered by the
  # scope of the granting `UserRole`.
  def define_scopable_abilities
    ACTIVITIES.each_pair do |subject, activities|
      next unless subject.try(:scopable_permissions?)
      activities.each do |activity|
        define_scopable_ability(subject, activity)
      end
    end
  end

  def define_scopable_ability(subject, activity)
    can activity, subject do |subject_instance|
      subject
        .granted_for(user: current_user, activity: activity)
        .where(id: subject_instance.id)
        .exists?
    end
  end

  ##
  # Basic abilities are granted irrespective of the permissions
  # defined in any role. For example, a user should always be
  # permitted to manage his own user account and his own public keys.
  def basic_abilities
    unless can?(:manage, User)
      can :manage, User, ['users.id = ?', current_user.id] do |user|
        user == current_user
      end
    end

    unless can?(:manage, PublicKey)
      can :manage, PublicKey, ['public_keys.user_id = ?', current_user.id] do |public_key|
        public_key.user == current_user
      end
    end
  end
end
