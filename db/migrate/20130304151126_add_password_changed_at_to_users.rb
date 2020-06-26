class AddPasswordChangedAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :password_changed_at, :datetime, default: nil
  end
end
