class CreatePermissions < ActiveRecord::Migration[4.2]
  def change
    create_table :permissions do |t|
      t.belongs_to :role, null: false, index: true
      t.string :activity, null: false, index: true
      t.string :subject, null: false, index: true
      t.timestamps null: false
    end
  end
end
