class CreateCenters < ActiveRecord::Migration
  def change
    create_table :centers do |t|
      t.string :name
      t.integer :study_id

      t.timestamps null: true
    end
  end
end
