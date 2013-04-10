class CreateCenters < ActiveRecord::Migration
  def change
    create_table :centers do |t|
      t.string :name
      t.reference :study

      t.timestamps
    end
  end
end
