class ImageSeriesData
  include Mongoid::Document

  include Mongoid::History::Trackable

  field :image_series_id, type: Integer
  field :properties, type: Hash, :default => {}
  field :properties_version, type: String

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

  def self.classify_mongoid_tracker_event(c)
    if((c.keys - ['properties', 'properties_version']).empty?)
      :properties_change
    end
  end
  def self.mongoid_tracker_event_title_and_severity(event_symbol)
    return case event_symbol
           when :properties_change then ['Properties Change', :ok]
           end
  end
end
