class Study < ActiveRecord::Base
  attr_accessible :name

  has_many :sessions

  has_many :roles, :as => :subject
end
