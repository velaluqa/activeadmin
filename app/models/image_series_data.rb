class ImageSeriesData
  include Mongoid::Document

  field :image_series_id, type: Integer
  field :properties, type: Hash, :default => {}

  def image_series
    begin
      return ImageSeries.find(read_attribute(:image_series_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def image_series=(image_series)
    write_attribute(:image_series_id, image_series.id)
  end
end
