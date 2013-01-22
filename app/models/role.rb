class Role < ActiveRecord::Base
  attr_accessible :role, :user, :subject
  attr_accessible :role_id, :user_id, :subject_id

  belongs_to :user
  belongs_to :subject, :polymorphic => true  

  ROLE_SYMS = [:manage, :validate, :blind_read]

  def self.role_sym_to_int(sym)
    return Role::ROLE_SYMS.index(sym)
  end

  def role
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
