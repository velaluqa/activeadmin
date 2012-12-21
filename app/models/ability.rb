class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.nil? # guest users have no access whatsoever

    is_app_admin? = !(user.roles.first(:conditions => { :object_type => nil, :object_id => nil, :role => Role::role_sym_to_int(:manage) }).nil?)

    # App Admin
    if is_app_admin?
      can :manage, User
      can :manage, Role
    end

    # Study Admin
    can :manage, Study do |study|
      !(study.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?)
    end

    # Session Admin
    can :manage, Session do |session|
      !(session.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?)
    end

    # Validator
    can :validate, Session do |session|
      !(session.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:validate)}).nil?)
    end

    # Reader
    can :blind_read, Session do |session|
      !(session.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:blind_read)}).nil?)
    end
  end
end
