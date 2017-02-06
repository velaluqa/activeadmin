module ScopablePermissions
  extend ActiveSupport::Concern

  included do
    def self.with_permissions
      raise <<ERROR
Scope `with_permissions` not defined in #{self}.
Make sure you override this method/scope to join the necessary permissions.
ERROR
    end

    ##
    # Filters all entities of a model, that are granted for given a `user` and
    # specific given `activities`.
    #
    # @param [Hash] options The options to extract activities from
    # @option options [User] :user The user object to filter by
    # @option options [String] :activity The activity
    # @option options [String] :activities The activities
    # @option options [Boolean] :include_manage (true) Whether to include the
    #   :manage activity.
    #
    # @return [ActiveRecord::Relation] The relation filtering granted records
    #
    def self.granted_for(options)
      activities = extract_permissible_activities(options)
      user = options[:user] || raise("Missing 'user' option")
      subject = options[:subject].andand.to_s || to_s

      return all if user.is_root_user?

      with_permissions
        .where(permissions: { activity: activities, subject: subject })
        .where('user_roles.user_id = ?', user.id)
    end

    ##
    # ~cancancan~ provides model additions like the ~accessible_by~
    # scope. The scoped records are those, which the current user's
    # roles grant certain access to. But ~cancancan~ tries to merge
    # the requested permission ~:read~ with the general ~:manage~
    # permission. Since ~:manage~ would also allow ~:read~ access. Our
    # ~joins~ are too complex for ~cancancan~ to merge.
    #
    # In our case, we already catch this relationship, with our
    # ~granted_for~ scope, so we have to teach ~cancancan~ not to
    # merge ~:read~ and ~:manage~ rules for certain abilities.
    # Overriding the ~accessible_by~ scope is the easiest way.
    #
    # @param [Ability] ability the ability to filter by
    # @param [Symbol] activity (:read)
    def self.accessible_by(ability, activity = :read)
      granted_for(user: ability.current_user, activity: activity).distinct
    end

    ##
    # Can be used to check, whether the model has scopable
    # permissions.
    #
    # @example Checking via Object#try
    #   MyModel.try(:scopable_permissions?)
    #
    def self.scopable_permissions?
      true
    end

    protected

    ##
    # Returns a `uniq` array of activities from given options hash.
    #
    # Note: This hash by default includes manage, since manage permits any
    # operation on a specific subject.
    #
    def self.extract_permissible_activities(options)
      options = { include_manage: true }.merge(options)
      activities = options[:include_manage] ? ['manage'] : []
      activities.push(options[:activities]) if options[:activities]
      activities.push(options[:activity]) if options[:activity]
      activities.flatten.map(&:to_s).uniq.compact
    end
  end
end
