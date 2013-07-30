class ImageSeriesData
  include Mongoid::Document

  include Mongoid::History::Trackable

  field :image_series_id, type: Integer
  field :properties, type: Hash, :default => {}

  index image_series_id: 1

  track_history :track_create => true, :track_update => true, :track_destroy => true

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
