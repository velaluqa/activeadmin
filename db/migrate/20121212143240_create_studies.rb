class CreateStudies < ActiveRecord::Migration[4.2]
  def change
    create_table :studies do |t|
      t.string :name

      t.timestamps null: true
    end
  end
end
