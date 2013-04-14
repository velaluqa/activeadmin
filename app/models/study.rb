class Study < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name

  has_many :sessions

  has_many :roles, :as => :subject

  has_many :centers

  validates_presence_of :name

  before_destroy do
    unless(sessions.empty? and centers.empty?)
      errors.add :base, 'You cannot delete a study that still has sessions or centers associated with it.'
      return false
    end
  end

  def image_storage_path
    Rails.application.config.image_storage_root + '/' + self.id.to_s
  end
end
