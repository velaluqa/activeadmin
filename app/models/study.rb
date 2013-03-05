class Study < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name

  has_many :sessions

  has_many :roles, :as => :subject

  before_destroy do
    unless sessions.empty?
      errors.add :base, 'You cannot delete a study that still has sessions associated with it.'
      return false
    end
  end
end
