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

    # this is just for the simplified prototype auth system, either you are an admin or you're not
    if user.is_app_admin?
      can :manage, :all
    end

    return
    # everything down below is for the actual, proper auth system that is not yet in place

    # App Admin
    if user.is_app_admin?
      can :manage, :all
      can :manage, User
      can :manage, Role
      can :manage, Study
    end

    # Study Admin
    can :manage, Study do |study|
      !(study.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?)
    end

    # Session Admin
    can :manage, Session do |session|
      puts "CAN MANAGE SESSION?: #{session}"
      !(session.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?) or
        !(session.study.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?)
    end

    can :manage, Case do |c|
      puts "CAN MANAGE CASE?: #{c}"
      can? :manage, c.session
    end
    can :manage, CaseData do |cd|
      puts "CAN MANAGE CASEDATA?: #{cd}"
      can? :manage, cd.case
    end
    can :manage, FormAnswer do |form_answer|
      puts "CAN MANAGE FORMANSWER?: #{form_answer}"
      can? :manage, form_answer.session
    end
    can :read, Form do |form|
      puts "CAN READ FORM?: #{form}"
      form.session.nil?
    end
    can :manage, Form do |form|
      puts "CAN MANAGE FORM?: #{form}"
      user.is_app_admin? or (can? :manage, form.session)
    end
    can :manage, Patient do |patient|
      puts "CAN MANAGE PATIENT?: #{patient}"
      can? :manage, patient.session
    end
    can :manage, PatientData do |pd|
      puts "CAN MANAGE PATIENTDATA?: #{pd}"
      can? :manage, pd.patient
    end

  end
end
