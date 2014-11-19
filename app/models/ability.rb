class Ability
  include CanCan::Ability  
  
  def initialize(user)
    return if user.nil? # guest users have no access whatsoever
    
    return if user.roles.empty?
    
    can [:read, :batch_action, :download_zip, :destroy], BackgroundJob do |job|
      job.user_id == user.id
    end

    # ERICA Remote
    if Rails.application.config.is_erica_remote
      if user.is_app_admin?
        can :manage, :system
        can :manage, User
        can :manage, Role
        can :manage, PublicKey
        can :manage, Study
      end

      # handle :remote_manage
      if user.is_erica_remote_admin?
        can :read, [User, Role, PublicKey]
        can :create, User
        can :new, Role
        can :create, Role do |role|
          role.user and role.user.is_erica_remote_user? and role.erica_remote_role?
        end
        can [:update, :destroy], Role do |role|
          role.erica_remote_role? and not (role.user and role.user.id == user.id and role.role == :remote_manage)
        end
        can [:update, :destroy], User do |user_to_edit|
          user_to_edit.is_erica_remote_user?
        end
      end

      # handle :remote_read
      if(user.has_system_role?(:remote_read))
        can :read, [Study, Center, Patient, Visit, ImageSeries, Image]
      elsif(not user.roles.where(role: Role.role_sym_to_int(:remote_read)).empty?)
        can :read, Study, ['id IN '+STUDY_REMOTE_ROLES_SUBQUERY, Role.role_sym_to_int(:remote_read), user.id] do |study|
          !study.roles.first(:conditions => { :user_id => user.id, :role => Role.role_sym_to_int(:remote_read)}).nil?
        end
        can :read, Center, ['centers.study_id IN '+STUDY_REMOTE_ROLES_SUBQUERY, Role.role_sym_to_int(:remote_read), user.id] do |center|
          can? :read, center.study
        end
        can :read, Patient, Patient.includes(:center).where('centers.study_id IN '+STUDY_REMOTE_ROLES_SUBQUERY, Role.role_sym_to_int(:remote_read), user.id) do |patient|
          can? :read, patient.study
        end
        can :read, Visit, Visit.includes(:patient => :center).where('centers.study_id IN '+STUDY_REMOTE_ROLES_SUBQUERY, Role.role_sym_to_int(:remote_read), user.id) do |visit|
          can? :read, visit.study
        end
        can :read, ImageSeries, ImageSeries.includes(:patient => :center).where('centers.study_id IN '+STUDY_REMOTE_ROLES_SUBQUERY, Role.role_sym_to_int(:remote_read), user.id) do |image_series|
          can? :read, iamge_series.study
        end
        can :read, Image, Image.includes(:image_series => {:patient => :center}).where('centers.study_id IN '+STUDY_REMOTE_ROLES_SUBQUERY, Role.role_sym_to_int(:remote_read), user.id) do |image|
          can? :read, iamge.study
        end
      end

      # handle :remote_comment
      can :remote_comment, Study do |study|
        user.has_system_role?(:remote_comment) or (
          study.roles.first(:conditions => { :user_id => user.id, :role => Role.role_sym_to_int(:remote_comment)}).nil?
        )
      end
      can :remote_comment, [Center, Patient, Visit, ImageSeries, Image] do |resource|
        can? :remote_comment, resource.study
      end

      if(user.has_system_role?(:remote_comments))
        can [:read, :create], ActiveAdmin::Comment do |comment|
          can? :remote_comment, comment.resource
        end
        can [:update, :destroy], ActiveAdmin::Comment do |comment|
          can? :remote_comment, comment.resource and comment.author_id == user.id and comment.author_type == 'User'
        end
      end

      # handle :remote_audit
      can :read, Version if(user.has_system_role?(:remote_audit))

      # handle :remote_images
      if(user.has_system_role?(:remote_images))
        can :download_images, [Study, Patient, Visit]
      elsif(not user.roles.where(role: Role.role_sym_to_int(:remote_images)).empty?)
        can :download_images, Study do |study|
          !study.roles.first(:conditions => { :user_id => user.id, :role => Role.role_sym_to_int(:remote_images)}).nil?
        end
        can :download_images, Patient do |patient|
          can? :download_images, patient.study
        end
        can :download_images, Visit do |visit|
          can? :download_images, visit.study
        end
      end

      # handle :remote_qc
      if(user.has_system_role?(:remote_qc))
        can :read_qc, Study
        can :read_qc, Visit
      elsif(not user.roles.where(role: Role.role_sym_to_int(:remote_qc)).empty?)
        can :read_qc, Study do |study|
          !study.roles.first(:conditions => { :user_id => user.id, :role => Role.role_sym_to_int(:remote_qc)}).nil?
        end
        can :read_qc, Visit do |visit|
          can? :read_qc, visit.study
        end
      end

      # TODO: handle :remote_keywords

      return
    end
    
    # App Admin
    if user.is_app_admin?
      can :manage, :system
      can :manage, Version
      can :manage, MongoidHistoryTracker
      can :manage, User
      can :manage, Role
      can :manage, PublicKey
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
    else
      can :read, PublicKey, ['public_keys.user_id = ?', user.id] do |public_key|
        public_key.user == user
      end
      can :read, User, ['users.id = ?', user.id] do |db_user|
        db_user == user
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
    unless user.is_app_admin?
      can :read, Version
      can :git_commits, Version
      can :show_git_commit, Version
      can :read, MongoidHistoryTracker
    end

    can :read, Study, ['id IN '+STUDY_AUDIT_ROLES_SUBQUERY, user.id] do |study|
      !study.roles.first(:conditions => { :user_id => user.id, :role => [Role.role_sym_to_int(:audit), Role.role_sym_to_int(:readonly)]}).nil?
    end
    unless(self.can? :read, Center)
      can :read, Center, ['centers.study_id IN '+STUDY_AUDIT_ROLES_SUBQUERY, user.id] do |center|
        can? :read, center.study
      end
    end
    unless(self.can? :read, Patient)
      can :read, Patient, Patient.includes(:center).where('centers.study_id IN '+STUDY_AUDIT_ROLES_SUBQUERY, user.id) do |patient|
        can? :read, patient.study
      end
    end
    unless(self.can? :read, Visit)
      can :read, Visit, Visit.includes(:patient => :center).where('centers.study_id IN '+STUDY_AUDIT_ROLES_SUBQUERY, user.id) do |visit|
        can? :read, visit.study
      end
    end
    unless(self.can? :read, ImageSeries)
      can :read, ImageSeries, ImageSeries.includes(:patient => :center).where('centers.study_id IN '+STUDY_AUDIT_ROLES_SUBQUERY, user.id) do |image_series|
        can? :read, image_series.study
      end
    end
    unless(self.can? :read, Image)
      can :read, Image, Image.includes(:image_series => {:patient => :center}).where('centers.study_id IN '+STUDY_AUDIT_ROLES_SUBQUERY, user.id) do |image|
        can? :read, image.study
      end
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

    can :read, PatientData do |pd|
      can? :read, pd.patient
    end
  end

  # this is somewhat of a hack so we can check whether a user can create/edit a template form without actually having a template form object
  def self.can_manage_template_forms?(user)
    user.is_app_admin?
  end
  
  protected
  SESSION_ROLES_SUBQUERY = 'SELECT roles.subject_id FROM roles INNER JOIN sessions ON roles.subject_id = sessions.id WHERE roles.subject_type LIKE \'Session\' AND roles.role = 0 AND roles.user_id = ?'
  SESSION_STUDY_ROLES_SUBQUERY = '(SELECT sessions.id FROM sessions WHERE sessions.study_id IN (SELECT roles.subject_id FROM roles INNER JOIN studies ON roles.subject_id = studies.id WHERE roles.subject_type LIKE \'Study\' AND roles.role = 0 AND roles.user_id = ?) UNION ALL '+SESSION_ROLES_SUBQUERY+')'

  MQC_STUDY_ROLES_SUBQUERY = '(SELECT roles.subject_id FROM roles WHERE roles.subject_type LIKE \'Study\' AND roles.role = 3 AND roles.user_id = ?)'

  STUDY_AUDIT_ROLES_SUBQUERY = '(SELECT roles.subject_id FROM roles WHERE roles.subject_type LIKE \'Study\' AND (roles.role = 4 OR roles.role = 5) AND roles.user_id = ?)'
  SESSION_AUDIT_ROLES_SUBQUERY = 'SELECT roles.subject_id FROM roles INNER JOIN sessions ON roles.subject_id = sessions.id WHERE roles.subject_type LIKE \'Session\' AND (roles.role = 4 OR roles.role = 5) AND roles.user_id = ?'
  SESSION_STUDY_AUDIT_ROLES_SUBQUERY = '(SELECT sessions.id FROM sessions WHERE sessions.study_id IN (SELECT roles.subject_id FROM roles INNER JOIN studies ON roles.subject_id = studies.id WHERE roles.subject_type LIKE \'Study\' AND (roles.role = 4 OR roles.role = 5) AND roles.user_id = ?) UNION ALL '+SESSION_AUDIT_ROLES_SUBQUERY+')'

  STUDY_REMOTE_ROLES_SUBQUERY = '(SELECT roles.subject_id FROM roles WHERE roles.subject_type LIKE \'Study\' AND roles.role = ? AND roles.user_id = ?)'
end
