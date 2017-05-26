class AddSeriesNumberToImageSeries < ActiveRecord::Migration
  def change
    add_column :image_series, :series_number, :integer
    add_index(:image_series, %i[patient_id series_number], unique: true)
  end
end
