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

  def previous_image_storage_path
    image_storage_path
  end
  def image_storage_path
    self.id.to_s
  end

  def all_patients
    Patient.where('center_id IN ?', self.centers.map {|c| c.id})
  end
end
