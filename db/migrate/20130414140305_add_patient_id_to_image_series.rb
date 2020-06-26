class AddPatientIdToImageSeries < ActiveRecord::Migration[4.2]
  def change
    add_column :image_series, :patient_id, :integer
  end
end
