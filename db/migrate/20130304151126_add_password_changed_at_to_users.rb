class AddPasswordChangedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :password_changed_at, :datetime, default: nil
  end
end
