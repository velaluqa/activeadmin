class ImageSeries < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name, :visit_id
  attr_accessible :visit

  belongs_to :visit
  #has_many :images, :dependent => :destroy
  
  validates_uniqueness_of :name, :scopy => :visit_id
  validates_presence_of :name

  scope :not_assigned, where(:visit_id => nil)
end
