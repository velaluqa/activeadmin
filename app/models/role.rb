class Role < ActiveRecord::Base
  attr_accessible :role, :user, :object

  belongs_to :user
  belongs_to :object, :polymorphic => true  

  ROLE_SYMS = [:manage, :validate, :read]

  def role
    return ROLE_SYMS[read_attribute(:role)]
  end
  def role=(sym)
    index = ROLE_SYMS.index(sym)

    if index.nil?
      throw "Unsupported role"
      return
    end

    write_attribute(:role, index)
  end
end
