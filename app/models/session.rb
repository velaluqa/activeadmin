class Session < ActiveRecord::Base
  attr_accessible :name, :study

  belongs_to :study

  has_many :roles, :as => :object
end
