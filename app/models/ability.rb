class Ability
  include CanCan::Ability

  attr_reader :current_user

  ACTIVITIES = {
    BackgroundJob => %i[manage read destroy cancel],
    Sidekiq => %i[manage],
    Configuration => %i[manage read],
    Study  => %i[manage read update create destroy comment read_reports read_tags create_tags update_tags configure clean_dicom_metadata change_domino_config],
    Center => %i[manage read update create destroy comment read_tags update_tags create_tags],
    Patient => %i[manage read update create destroy comment download_images read_tags update_tags create_tags],
    EmailTemplate => %i[manage read update create destroy],
    ImageSeries => %i[manage read update destroy comment upload assign_patient assign_visit viewer read_dicom_metadata clean_dicom_metadata read_tags update_tags create_tags],
    FormSession => %i[manage read update create destroy],
    FormDefinition => %i[manage read update create destroy],
    FormAnswer => %i[manage read update create destroy],
    NotificationProfile => %i[manage read update create destroy simulate_recipients],
    Notification => %i[manage read update create destroy],
    User => %i[manage read update create destroy generate_keypair impersonate confirm_mail unlock change_password read_tags create_tags update_tags],
    UserRole => %i[manage read update create destroy],
    PublicKey => %i[manage read update create destroy],
    RequiredSeries => %i[manage read update],
    Role => %i[manage read update create destroy],
    Visit => %i[manage read update create destroy comment download_images read_tags update_tags create_tags create_from_template update_state assign_required_series read_tqc perform_tqc read_mqc perform_mqc],
    Version => %i[manage read update create destroy git_commits]
  }.freeze

  UNSCOPABLE_ACTIVITIES = {
    BackgroundJob => %i[manage read update create destroy],
    ImageSeries => %i[upload assign_patient assign_visit],
    Visit => %i[assign_required_series]
  }.freeze

  def can_with_undecorate?(action, subject, attribute = nil, *extra_args)
    undecorated_subject = Draper.undecorate(subject)

    return false unless available?(action, undecorated_subject)

    can_without_undecorate?(
      action,
      undecorated_subject,
      attribute,
      *extra_args
    )
  end
  alias_method :can_without_undecorate?, :can?
  alias_method :can?, :can_with_undecorate?

  def initialize(current_user)
    @current_user = current_user
    return unless @current_user

    if current_user.is_root_user?
      can :manage, ACTIVITIES.keys
      can :manage, Image
    else
      define_system_wide_abilities
      define_scopable_abilities
      define_basic_abilities
    end

    define_dynamic_abilities

    define_page_abilities
  end

  def permissions
    @permissions ||=
      @current_user.permissions.map { |p| [p.ability, true] }.to_h
  end

  private

  def unscopable?(subject, activity)
    UNSCOPABLE_ACTIVITIES[subject].andand.include?(activity)
  end

  # Returns true if any permission associated with the user matches
  # given attributes.
  def any_permission?(subject, activity)
    permissions["#{activity}_#{subject.to_s.underscore}"]
  end

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
      activities.each do |activity|
        if unscopable?(subject, activity)
          define_unscopable_ability(subject, activity)
        elsif subject.try(:scopable_permissions?)
          define_scopable_ability(subject, activity)
          proxy_image_activity(activity) if subject == ImageSeries
        end
      end
    end
  end

  def proxy_image_activity(activity)
    return unless any_permission?(ImageSeries, activity)

    can activity, Image do |image|
      if image.new_record?
        can?(activity, ImageSeries)
      else
        ImageSeries
          .granted_for(user: current_user, activity: activity)
          .where(id: image.image_series_id)
          .exists?
      end
    end
  end

  def define_scopable_ability(subject, activity)
    return unless any_permission?(subject, activity)
    can activity, subject do |subject_instance|
      if subject_instance.new_record?
        can?(activity, subject_instance.class)
      else
        subject
          .granted_for(user: current_user, activity: activity)
          .where(id: subject_instance.id)
          .exists?
      end
    end
  end

  def define_unscopable_ability(subject, activity)
    return unless current_user.permissions.allow?(activity, subject)
    can(activity, subject)
  end

  def define_dynamic_abilities
    can %i[read create], ActiveAdmin::Comment do |comment|
      can?(:comment, comment.resource)
    end
    can %i[update], ActiveAdmin::Comment do |comment|
      can?(:comment, comment.resource) && comment.author_id == current_user.id
    end
  end

  ##
  # Basic abilities are granted irrespective of the permissions
  # defined in any role. For example, a user should always be
  # permitted to manage his own user account, his own background jobs
  # and his own public keys.
  def define_basic_abilities
    unless can?(:manage, BackgroundJob)
      can %i[read update create destroy], BackgroundJob, ['background_jobs.user_id = ?', current_user.id] do |background_job|
        background_job.user == current_user
      end
    end

    unless can?(:manage, User)
      can %i[read update generate_keypair change_password], User, ['users.id = ?', current_user.id] do |user|
        user == current_user
      end
    end

    unless can?(:manage, PublicKey)
      can %i[read update], PublicKey, ['public_keys.user_id = ?', current_user.id] do |public_key|
        public_key.user == current_user
      end
    end
  end

  def define_page_abilities
    can :read, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'

    if can?(:viewer, ImageSeries)
      can :read, ActiveAdmin::Page, name: 'Viewer Cart', namespace_name: 'admin'
      can :start, ActiveAdmin::Page, name: 'Viewer Cart', namespace_name: 'admin'
      can :clear, ActiveAdmin::Page, name: 'Viewer Cart', namespace_name: 'admin'
      can :remove, ActiveAdmin::Page, name: 'Viewer Cart', namespace_name: 'admin'
      can :empty, ActiveAdmin::Page, name: 'Viewer Cart', namespace_name: 'admin'
    end

    if can?(:manage, Sidekiq)
      can :read, ActiveAdmin::Page, name: 'Sidekiq', namespace_name: 'admin'
    end

    if can?(:upload, ImageSeries)
      can :read, ActiveAdmin::Page, name: 'Image Upload', namespace_name: 'admin'
    end
  end

  private

  def all_available?(actions, subject)
    actions.map { |action| available?(action, subject) }.all?
  end

  def available?(action, subject)
    return all_available?(action, subject) if action.is_a?(Array)

    # Basic ActiveAdmin actions should always be available
    return true if %i[create read edit update destroy].include?(action)

    is_available =
      case subject
      when ApplicationRecord, PaperTrail::Version
        Array(ACTIVITIES[subject.class]).include?(action)
      else
        !ACTIVITIES.key?(subject) || ACTIVITIES[subject].include?(action)
      end

    if !is_available && !Rails.env.production?
      raise "#{action} is not available for #{subject}. You might want to add it to Ability::ACTIVITIES"
    end

    is_available
  end
end
