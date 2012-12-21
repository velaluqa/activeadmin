class Session < ActiveRecord::Base
  attr_accessible :name, :study

  belongs_to :study

  has_many :roles, :as => :object
  has_one :user
  has_many :form_answers
  has_many :patients
  has_many :session_pauses
  has_many :forms
end
