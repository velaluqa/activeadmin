class AddKeyPairToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :public_key, :binary
    add_column :users, :private_key, :binary
  end
end
