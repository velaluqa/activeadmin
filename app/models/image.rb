class Image < ActiveRecord::Base
  has_paper_trail
  
  attr_accessible :image_series_id
  attr_accessible :image_series

  belongs_to :image_series

  validates_presence_of :image_series_id
end
