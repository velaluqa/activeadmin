class Ability
  include CanCan::Ability  

  def initialize(user)
    return if user.nil? # guest users have no access whatsoever

    alias_action :read, :create, :update, :destroy, :to => :administrate

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
      can :administrate, :all
    end

    return
    # everything down below is for the actual, proper auth system that is not yet in place

    # App Admin
    if user.is_app_admin?
      can :administrate, :all
      can :administrate, User
      can :administrate, Role
      can :administrate, Study
    end

    # Study Admin
    can :administrate, Study do |study|
      !(study.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?)
    end

    # Session Admin
    can :administrate, Session do |session|
      puts "CAN MANAGE SESSION?: #{session}"
      !(session.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?) or
        !(session.study.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?)
    end

    can :administrate, Case do |c|
      puts "CAN MANAGE CASE?: #{c}"
      can? :administrate, c.session
    end
    can :administrate, CaseData do |cd|
      puts "CAN MANAGE CASEDATA?: #{cd}"
      can? :administrate, cd.case
    end
    can :administrate, FormAnswer do |form_answer|
      puts "CAN MANAGE FORMANSWER?: #{form_answer}"
      can? :administrate, form_answer.session
    end
    can :read, Form do |form|
      puts "CAN READ FORM?: #{form}"
      form.session.nil?
    end
    can :administrate, Form do |form|
      puts "CAN MANAGE FORM?: #{form}"
      user.is_app_admin? or (can? :administrate, form.session)
    end
    can :administrate, Patient do |patient|
      puts "CAN MANAGE PATIENT?: #{patient}"
      can? :administrate, patient.session
    end
    can :administrate, PatientData do |pd|
      puts "CAN MANAGE PATIENTDATA?: #{pd}"
      can? :administrate, pd.patient
    end

  end
end
