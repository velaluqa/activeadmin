class AddImagingDateToImageSeries < ActiveRecord::Migration
  def change
    add_column :image_series, :imaging_date, :date
  end
end
