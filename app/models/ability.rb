class Ability
  include CanCan::Ability  

  def initialize(user)
    return if user.nil? # guest users have no access whatsoever

    return if user.roles.empty?

    can [:read, :destroy], BackgroundJob do |job|
      job.user_id == user.id
    end

    # App Admin
    if user.is_app_admin?
      can :manage, :system
      can :manage, Version
      can :manage, User
      can :manage, Role
      can :manage, Study
      can :read, Center
      can :read, Patient
      can :read, Visit
      can :read, ImageSeries
      can :read, Image
      can [:create, :read, :edit, :destroy], Session
      can :manage, Form, ['forms.session_id IS NULL'] do |form|
        form.is_template?
      end
    end

    if(user.has_system_role?(:image_import))
      can :read, Study
      can [:create, :read], Center
      can [:create, :read], Patient
      can [:create, :read], Visit
      can [:create, :read], ImageSeries
      can [:create, :read], Image
    end
    if(user.has_system_role?(:image_manage))
      can :image_manage, :system
      can :manage, Study
      can :manage, Center
      can :manage, Patient
      can :manage, Visit
      can :manage, ImageSeries
      can :manage, Image
    end

    # handle mQC roles
    # we have to do this in this slightly awkward fassion to allow fetching visit records for any combination of image uploader/manager and mqc role
    unless(user.roles.where(:user_id => user.id, :role => Role.role_sym_to_int(:medical_qc)).empty?)
      can :mqc, Study, Study.where('id IN '+MQC_STUDY_ROLES_SUBQUERY, user.id) do |study|
        !study.roles.first(:conditions => { :user_id => user.id, :role => Role.role_sym_to_int(:medical_qc)}).nil?
      end
      if(not (user.has_system_role?(:image_import) or user.has_system_role?(:image_manage) or user.is_app_admin?))
        can [:read, :mqc], Visit, Visit.includes(:patient => :center).where('centers.study_id IN '+MQC_STUDY_ROLES_SUBQUERY, user.id) do |visit|
          can? :mqc, visit.study
        end
        can :read, ImageSeries, ImageSeries.includes(:patient => :center).where('centers.study_id IN '+MQC_STUDY_ROLES_SUBQUERY, user.id) do |image_series|
          can? :mqc, image_series.study
        end
        can :read, Image do |image|
          can? :read, image.image_series
        end
      elsif(user.has_system_role?(:image_import))
        can :mqc, Visit, Visit.includes(:patient => :center).where('centers.study_id IN '+MQC_STUDY_ROLES_SUBQUERY, user.id) do |visit|
          can? :mqc, visit.study
        end      
      end
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

    can :manage, PatientData do |pd|
      can? :manage, pd.patient
    end

    # Audit role
    can :read, Version
    can :read, Session, ['sessions.id IN '+SESSION_STUDY_AUDIT_ROLES_SUBQUERY, user.id, user.id] do |session|
      !(session.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:audit)}).nil?) or
        (session.study and !(session.study.roles.first(:conditions => { :user_id => user.id, :role => Role::role_sym_to_int(:audit)}).nil?))      
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

  MQC_STUDY_ROLES_SUBQUERY = '(SELECT roles.subject_id FROM roles WHERE roles.subject_type LIKE \'Study\' AND roles.role = 3 AND roles.user_id = ?)'

  SESSION_AUDIT_ROLES_SUBQUERY = 'SELECT roles.subject_id FROM roles INNER JOIN sessions ON roles.subject_id = sessions.id WHERE roles.subject_type LIKE \'Session\' AND roles.role = 4 AND roles.user_id = ?'
  SESSION_STUDY_AUDIT_ROLES_SUBQUERY = '(SELECT sessions.id FROM sessions WHERE sessions.study_id IN (SELECT roles.subject_id FROM roles INNER JOIN studies ON roles.subject_id = studies.id WHERE roles.subject_type LIKE \'Study\' AND roles.role = 4 AND roles.user_id = ?) UNION ALL '+SESSION_AUDIT_ROLES_SUBQUERY+')'
end
