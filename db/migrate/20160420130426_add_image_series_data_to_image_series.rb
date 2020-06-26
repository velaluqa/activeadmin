class AddImageSeriesDataToImageSeries < ActiveRecord::Migration[4.2]
  def change
    add_column :image_series, :properties, :jsonb, null: false, default: {}
    add_column :image_series, :properties_version, :string, null: true
  end
end
