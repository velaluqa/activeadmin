class AddIsRootUserToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_root_user, :boolean, null: false, default: false
  end
end
