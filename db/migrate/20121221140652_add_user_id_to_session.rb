class AddUserIdToSession < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :user_id, :integer
  end
end
