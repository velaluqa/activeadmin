class ChangeKeysInUsers < ActiveRecord::Migration
  def up
    change_column :users, :private_key, :text, limit: nil
    change_column :users, :public_key, :text, limit: nil
  end

  def down
    change_column :users, :private_key, :string
    change_column :users, :public_key, :string
  end
end
