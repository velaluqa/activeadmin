class AddPatientIdToImageSeries < ActiveRecord::Migration
  def change
    add_column :image_series, :patient_id, :integer
  end
end
