class AddImageSeriesDataToImageSeries < ActiveRecord::Migration
  def change
    add_column :image_series, :properties, :jsonb, null: false, default: {}
    add_column :image_series, :properties_version, :string, null: true
  end
end
