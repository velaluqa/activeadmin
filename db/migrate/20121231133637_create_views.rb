class CreateViews < ActiveRecord::Migration
  def change
    create_table :views do |t|
      t.integer :position
      t.references :session
      t.references :patient
      t.references :form
      t.string :images

      t.timestamps :null => true
    end
    add_index :views, :session_id
    add_index :views, :patient_id
    add_index :views, :form_id

    add_index(:views, [:session_id, :position], :unique => true)
  end
end
