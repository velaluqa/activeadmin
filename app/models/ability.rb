class Ability
  include CanCan::Ability

  attr_reader :current_user

  ACTIVITIES = {
    BackgroundJob => %i(manage read update create destroy),
    Sidekiq => %i(manage),
    Study  => %i(manage read update create destroy),
    Center => %i(manage read update create destroy),
    Patient => %i(manage read update create destroy),
    ImageSeries => %i(manage read update create destroy upload assign_patient assign_visit),
    Image => %i(manage read update create destroy),
    User => %i(manage read update create destroy),
    UserRole => %i(manage read update create destroy),
    PublicKey => %i(manage read update create destroy),
    Role => %i(manage read update create destroy),
    Visit => %i(manage read update create destroy assign_required_series technical_qc medical_qc),
    Version => %i(manage read update create destroy)
  }.freeze

  def initialize(current_user)
    @current_user = current_user
    return unless @current_user

    if current_user.is_root_user?
      can :manage, ACTIVITIES.keys
    else
      define_system_wide_abilities
      define_scopable_abilities
      define_basic_abilities
    end

    define_page_abilities
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
    return unless subject.granted_for(user: current_user, activity: activity).exists?

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
  def define_basic_abilities
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

  def define_page_abilities
    can :read, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
    can :read, ActiveAdmin::Page, name: 'Viewer Cart', namespace_name: 'admin'
    if can?(:manage, Sidekiq)
      can :read, ActiveAdmin::Page, name: 'Sidekiq', namespace_name: 'admin'
    end
    if can?(:upload, ImageSeries)
      can :read, ActiveAdmin::Page, name: 'Image Upload', namespace_name: 'admin'
    end
  end
end
