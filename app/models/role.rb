class Role < ActiveRecord::Base
  has_paper_trail

  attr_accessible :role, :user, :subject
  attr_accessible :role_id, :user_id, :subject_id, :subject_type

  belongs_to :user
  belongs_to :subject, :polymorphic => true  

  ROLE_SYMS = [:manage, :image_import, :image_manage, :medical_qc, :audit, :readonly, :remote_manage, :remote_read, :remote_comments, :remote_images, :remote_keywords, :remote_audit, :remote_qc, :remote_status_files, :remote_define_keywords]
  ROLE_NAMES = ['Manager', 'Image Import', 'Image Manager', 'Medical QC', 'Audit', 'Read-only', 'ERICA Remote Manager', 'Remote - Read Access', 'Remote - Comments Access', 'Remote - Download Images', 'Remote - Set Keywords', 'Remote - Audit', 'Remote - QC Access', 'Remote - Status File Access', 'Remote - Define Keywords']

  before_save :fix_subject

  def fix_subject
    if self.subject_type =~ /study_([0-9]+)/
      self.subject_id = $1
      self.subject_type = 'Study'
    elsif self.subject_type =~ /session_([0-9]+)/
      self.subject_id = $1
      self.subject_type = 'Session'
    elsif self. subject_type.nil? or self.subject_type.empty?
      self.subject_type = nil
      self.subject_id = nil
    end
  end

  def system_role?
    subject_type == nil and subject_id == nil
  end
  def erica_remote_role?
    [:remote_manage, :remote_read, :remote_comments, :remote_images, :remote_keywords, :remote_audit, :remote_qc, :remote_status_files, :remote_define_keywords].include?(self.role)
  end

  def name
    return "#{role_name} on '#{subject_name}'"
  end
  def subject_name
    if(subject.nil?)
      'System'
    elsif(subject.respond_to?(:name))
      subject.name
    else
      subject.to_s
    end
  end

  def self.role_sym_to_int(sym)
    return Role::ROLE_SYMS.index(sym)
  end
  def self.role_sym_to_role_name(sym)
    return ROLE_NAMES[Role::ROLE_SYMS.index(sym)]
  end

  def role_name
    return Role::ROLE_NAMES[read_attribute(:role)]
  end

  def role
    return -1 if read_attribute(:role).nil?
    return Role::ROLE_SYMS[read_attribute(:role)]
  end
  def role=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = Role::ROLE_SYMS.index(sym)

    if index.nil?
      throw "Unsupported role"
      return
    end

    write_attribute(:role, index)
  end
end
