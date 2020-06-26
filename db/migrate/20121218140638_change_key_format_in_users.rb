class ChangeKeyFormatInUsers < ActiveRecord::Migration[4.2]
  def up
    change_column :users, :private_key, :string
    change_column :users, :public_key, :string
  end

  def down
    change_column :users, :private_key, :binary
    change_column :users, :public_key, :binary
  end
end
