class CreateSessions < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.string :name
      t.references :study

      t.timestamps null: true
    end
  end
end
