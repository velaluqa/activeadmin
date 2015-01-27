class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.nil? # guest users have no access whatsoever

    # # Validator
    # can :validate, Session do |session|
    #   session.validators.exists?(user.id)
    # end

    # # Reader
    # can :blind_read, Session do |session|
    #   session.readers.exists?(user.id)
    # end

    # can :read, Session do |session|
    #   can? :validate, session or can? :blind_read, session
    # end

    return if user.roles.empty?

    # App Admin
    if user.is_app_admin?
      can :manage, :system
      can :manage, Version
      can :manage, MongoidHistoryTracker
      can :manage, User
      can :manage, Role
      can :manage, PublicKey
      can :manage, Study
      can [:create, :read, :edit, :destroy], Session
      can :manage, Form, ['forms.session_id IS NULL'] do |form|
        form.is_template?
      end
    else
      can :read, PublicKey, ['public_keys.user_id = ?', user.id] do |public_key|
        public_key.user == user
      end
      can :read, User, ['users.id = ?', user.id] do |db_user|
        db_user == user
      end
      can :read, Study
    end

    # Session Admin
    can :manage, Session, ['sessions.id IN '+SESSION_STUDY_ROLES_SUBQUERY, user.id, user.id] do |session|
      !(session.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?) or
        (session.study and !(session.study.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?))
    end

    can :manage, Case, ['cases.session_id IN '+SESSION_STUDY_ROLES_SUBQUERY, user.id, user.id] do |c|
      can? :manage, c.session
    end
    # possible record query for mongoid:
    # CaseData.in(case_id: Case.where('session_id IN '+SESSION_STUDY_ROLES_SUBQUERY, user.id).map{|c| c.id})
    # we don't need that though, since there is no index for case/patient data anyway and we can define the actual rights via the block
    can :manage, CaseData do |cd|
      can? :manage, cd.case
    end

    can :read, FormAnswer, FormAnswer.in(session_id: Session.where('id IN '+SESSION_STUDY_AUDIT_ROLES_SUBQUERY, user.id, user.id).map{|s| s.id}) do |form_answer|
      can? :read, form_answer.session
    end
    can :manage, FormAnswer, FormAnswer.in(session_id: Session.where('id IN '+SESSION_STUDY_ROLES_SUBQUERY, user.id, user.id).map{|s| s.id}) do |form_answer|
      can? :manage, form_answer.session
    end

    can :create, Form
    can :read, Form, ['forms.session_id IS NULL'] do |form|
      form.is_template?
    end
    can :manage, Form, ['forms.session_id IN '+SESSION_STUDY_ROLES_SUBQUERY, user.id, user.id] do |form|
      can? :manage, form.session
    end

    can :manage, Patient, ['patients.session_id IN '+SESSION_STUDY_ROLES_SUBQUERY, user.id, user.id] do |patient|
      can? :manage, patient.session
    end
    can :manage, PatientData do |pd|
      can? :manage, pd.patient
    end

    # Audit role
    unless user.is_app_admin?
      can :read, Version
      can :read, MongoidHistoryTracker
    end
    can :read, Session, ['sessions.id IN '+SESSION_STUDY_AUDIT_ROLES_SUBQUERY, user.id, user.id] do |session|
      !(session.roles.first(:conditions => { :user_id => user.id, :role => [Role::role_sym_to_int(:audit), Role::role_sym_to_int(:readonly)]}).nil?) or
        (session.study and !(session.study.roles.first(:conditions => { :user_id => user.id, :role => [Role::role_sym_to_int(:audit), Role::role_sym_to_int(:readonly)]}).nil?))
    end
    can :read, Case, ['cases.session_id IN '+SESSION_STUDY_AUDIT_ROLES_SUBQUERY, user.id, user.id] do |c|
      can? :read, c.session
    end
    can :read, CaseData do |cd|
      can? :read, cd.case
    end
    can :read, Form, ['forms.session_id IN '+SESSION_STUDY_AUDIT_ROLES_SUBQUERY, user.id, user.id] do |form|
      can? :read, form.session
    end

    can :read, Patient, ['patients.session_id IN '+SESSION_STUDY_AUDIT_ROLES_SUBQUERY, user.id, user.id] do |patient|
      can? :read, patient.session
    end
    can :read, PatientData do |pd|
      can? :read, pd.patient
    end
  end

  # this is somewhat of a hack so we can check whether a user can create/edit a template form without actually having a template form object
  def self.can_manage_template_forms?(user)
    user.is_app_admin?
  end

  protected
  APP_ADMIN_SUBQUERY = 'EXISTS(SELECT id FROM roles WHERE subject_type IS NULL and subject_id IS NULL AND role = 0 AND user_id = ?)'
  SESSION_ROLES_SUBQUERY = 'SELECT roles.subject_id FROM roles INNER JOIN sessions ON roles.subject_id = sessions.id WHERE roles.subject_type LIKE \'Session\' AND roles.role = 0 AND roles.user_id = ?'
  SESSION_STUDY_ROLES_SUBQUERY = '(SELECT sessions.id FROM sessions WHERE sessions.study_id IN (SELECT roles.subject_id FROM roles INNER JOIN studies ON roles.subject_id = studies.id WHERE roles.subject_type LIKE \'Study\' AND roles.role = 0 AND roles.user_id = ?) UNION ALL '+SESSION_ROLES_SUBQUERY+')'

  SESSION_AUDIT_ROLES_SUBQUERY = 'SELECT roles.subject_id FROM roles INNER JOIN sessions ON roles.subject_id = sessions.id WHERE roles.subject_type LIKE \'Session\' AND (roles.role = 4 OR roles.role = 5) AND roles.user_id = ?'
  SESSION_STUDY_AUDIT_ROLES_SUBQUERY = '(SELECT sessions.id FROM sessions WHERE sessions.study_id IN (SELECT roles.subject_id FROM roles INNER JOIN studies ON roles.subject_id = studies.id WHERE roles.subject_type LIKE \'Study\' AND (roles.role = 4 OR roles.role = 5) AND roles.user_id = ?) UNION ALL '+SESSION_AUDIT_ROLES_SUBQUERY+')'
end
