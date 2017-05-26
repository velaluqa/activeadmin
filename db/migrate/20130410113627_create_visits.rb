class CreateVisits < ActiveRecord::Migration
  def change
    create_table :visits do |t|
      t.integer :visit_number
      t.string :visit_type
      t.integer :patient_id

      t.timestamps null: true
    end
  end
end
