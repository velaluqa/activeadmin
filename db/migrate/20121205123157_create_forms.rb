class CreateForms < ActiveRecord::Migration
  def change
    create_table :forms do |t|
      t.string :name, :unique => true
      t.text :description

      t.timestamps :null => true
    end
  end
end
