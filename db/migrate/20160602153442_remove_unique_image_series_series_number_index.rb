class RemoveUniqueImageSeriesSeriesNumberIndex < ActiveRecord::Migration[4.2]
  def change
    remove_index(:image_series, %i[patient_id series_number])
    add_index(:image_series, %i[patient_id series_number], unique: false)
  end
end
