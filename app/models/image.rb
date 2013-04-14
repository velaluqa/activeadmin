class Image < ActiveRecord::Base
  has_paper_trail
  
  attr_accessible :image_series_id
  attr_accessible :image_series

  belongs_to :image_series

  validates_presence_of :image_series_id

  def image_storage_path
    self.image_series.image_storage_path + '/' + self.id.to_s
  end

  def file_is_present?
    File.readable?(image_storage_path)
  end
end
