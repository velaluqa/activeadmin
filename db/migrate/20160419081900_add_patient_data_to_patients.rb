class AddPatientDataToPatients < ActiveRecord::Migration[4.2]
  def change
    add_column :patients, :data, :jsonb, null: false, default: {}
    add_column :patients, :export_history, :jsonb, null: false, default: []
  end
end
