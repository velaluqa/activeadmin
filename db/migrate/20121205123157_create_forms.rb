class CreateForms < ActiveRecord::Migration[4.2]
  def change
    create_table :forms do |t|
      t.string :name, unique: true
      t.text :description

      t.timestamps null: true
    end
  end
end
