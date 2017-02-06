class CreatePatients < ActiveRecord::Migration
  def change
    create_table :patients do |t|
      t.string :subject_id
      t.string :images_folder
      t.references :session

      t.timestamps :null => true
    end
  end
end
