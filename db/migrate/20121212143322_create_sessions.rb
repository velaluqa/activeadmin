class CreateSessions < ActiveRecord::Migration[4.2]
  def change
    create_table :sessions do |t|
      t.string :name
      t.references :study

      t.timestamps null: true
    end
  end
end
