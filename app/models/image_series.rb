class ImageSeries < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name, :visit_id, :patient_id
  attr_accessible :visit, :patient

  belongs_to :visit
  belongs_to :patient
  has_many :images, :dependent => :destroy
  
  validates_uniqueness_of :name, :scopy => :visit_id
  validates_presence_of :name, :patient_id

  scope :not_assigned, where(:visit_id => nil)
end
