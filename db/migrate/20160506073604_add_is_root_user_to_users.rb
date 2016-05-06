class AddIsRootUserToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_root_user, :boolean, null: false, default: false
  end
end
