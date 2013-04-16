class Image < ActiveRecord::Base
  has_paper_trail
  
  attr_accessible :image_series_id
  attr_accessible :image_series

  belongs_to :image_series

  validates_presence_of :image_series_id

  def previous_image_storage_path
    if(self.previous_changes.include?(:image_series_id))
      previous_image_series = ImageSeries.find(self.previous_changes[:image_series_id][0])
      
      previous_image_series.image_storage_path + '/' + self.id.to_s
    else
      image_storage_path
    end
  end
  def image_storage_path
    self.image_series.image_storage_path + '/' + self.id.to_s
  end

  def file_is_present?
    File.readable?(Rails.application.config.image_storage_root + '/' + image_storage_path)
  end
end
