class Ability
  include CanCan::Ability  

  def initialize(user)
    return if user.nil? # guest users have no access whatsoever

    return if user.roles.empty?

    # App Admin
    if user.is_app_admin?
      can :manage, :system
      can :manage, Version
      can :manage, User
      can :manage, Role
      can :manage, Study
      can [:create, :read, :edit, :destroy], Session
      can :manage, Form, ['session_id IS NULL'] do |form|
        form.is_template?
      end
    end

    if(user.has_system_role?(:image_import))
      can [:create, :read], Center
      can [:create, :read], Patient
      # can [:create, :read], Visit
      # can [:create, :read], Series
      # can [:create, :read], Image
    end
    if(user.has_system_role?(:image_manage))
      can :manage, Study
      can :manage, Center
      can :manage, Patient
      # can :manage, Visit
      # can :manage, Series
      # can :manage, Image
    end

    # Session Admin
    can :manage, Session, ['id IN '+SESSION_ROLES_SUBQUERY, user.id] do |session|
      !(session.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?) or
        (session.study and !(session.study.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:manage)}).nil?))
    end

    can :manage, Case, ['session_id IN '+SESSION_ROLES_SUBQUERY, user.id] do |c|
      can? :manage, c.session
    end
    # possible record query for mongoid: 
    # CaseData.in(case_id: Case.where('session_id IN '+SESSION_ROLES_SUBQUERY, user.id).map{|c| c.id})
    # we don't need that though, since there is no index for case/patient data anyway and we can define the actual rights via the block
    can :manage, CaseData do |cd|
      can? :manage, cd.case      
    end

    can :manage, FormAnswer, FormAnswer.in(session_id: Session.where('id IN '+SESSION_ROLES_SUBQUERY, user.id).map{|s| s.id}) do |form_answer|
      can? :manage, form_answer.session
    end

    can :create, Form
    can :read, Form, ['session_id IS NULL'] do |form|
      form.is_template?
    end
    can :manage, Form, ['session_id IN '+SESSION_ROLES_SUBQUERY, user.id] do |form|
      can? :manage, form.session
    end

    can :manage, PatientData do |pd|
      can? :manage, pd.patient
    end
  end

  # this is somewhat of a hack so we can check whether a user can create/edit a template form without actually having a template form object
  def self.can_manage_template_forms?(user)
    user.is_app_admin?
  end

  protected
  APP_ADMIN_SUBQUERY = 'EXISTS(SELECT id FROM roles WHERE subject_type IS NULL and subject_id IS NULL AND role = 0 AND user_id = ?)'
  SESSION_ROLES_SUBQUERY = '(SELECT subject_id FROM roles INNER JOIN sessions ON roles.subject_id = sessions.id WHERE roles.subject_type LIKE \'Session\' AND role = 0 AND user_id = ?)'  
end
