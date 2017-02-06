class CreatePublicKeys < ActiveRecord::Migration
  def change
    create_table :public_keys do |t|
      t.integer :user_id, null: false
      t.text :public_key, null: false
      t.boolean :active, null: false
      t.datetime :deactivated_at

      t.timestamps :null => true
    end

    add_index :public_keys, :user_id
    add_index :public_keys, :active
  end
end
