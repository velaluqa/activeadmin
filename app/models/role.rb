class Role < ActiveRecord::Base
  attr_accessible :role, :user, :subject
  attr_accessible :role_id, :user_id, :subject_id

  belongs_to :user
  belongs_to :subject, :polymorphic => true  

  # ROLE_SYMS = [:manage, :validate, :blind_read]
  # ROLE_NAMES = ['Manager', 'Validator', 'Reader']
  ROLE_SYMS = [:manage]
  ROLE_NAMES = ['Manager']

  def self.role_sym_to_int(sym)
    return Role::ROLE_SYMS.index(sym)
  end

  def role_name
    return Role::ROLE_NAMES[read_attribute(:role)]
  end

  def role
    return -1 if read_attribute(:role).nil?
    return Role::ROLE_SYMS[read_attribute(:role)]
  end
  def role=(sym)
    index = Role::ROLE_SYMS.index(sym)

    if index.nil?
      throw "Unsupported role"
      return
    end

    write_attribute(:role, index)
  end
end
