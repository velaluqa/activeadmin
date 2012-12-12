class Role < ActiveRecord::Base
  attr_accessible :role, :user, :object

  belongs_to :user
  belongs_to :object, :polymorphic => true  
end
