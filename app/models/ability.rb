class Ability
  include CanCan::Ability  

  def initialize(user)
    return if user.nil? # guest users have no access whatsoever

    # Validator
    can :validate, Session do |session|
      session.validators.exists?(user.id)
    end

    # Reader
    can :blind_read, Session do |session|
      session.readers.exists?(user.id)
    end

    can :read, Session do |session|
      can? :validate, session or can? :blind_read, session
    end

    # App Admin
    if user.is_app_admin?
      can :manage, :system
      can :manage, User
      can :manage, Role
      can :manage, Study
    end

    # Session Admin
    can :manage, Session do |session|
      !(session.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?) or
        !(session.study.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?)
    end

    can :manage, Case do |c|
      can? :manage, c.session
    end
    can :manage, CaseData do |cd|
      can? :manage, cd.case
    end
    can :manage, FormAnswer do |form_answer|
      can? :manage, form_answer.session
    end
    can :read, Form do |form|
      form.session.nil?
    end
    can :manage, Form do |form|
      if(form.is_template?)
        user.is_app_admin?
      else
        can? :manage, form.session
      end
    end
    can :manage, Patient do |patient|
      can? :manage, patient.session
    end
    can :manage, PatientData do |pd|
      can? :manage, pd.patient
    end
  end
end
