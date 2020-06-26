class AddImagingDateToImageSeries < ActiveRecord::Migration[4.2]
  def change
    add_column :image_series, :imaging_date, :date
  end
end
