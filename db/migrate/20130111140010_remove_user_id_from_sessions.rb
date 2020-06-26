class RemoveUserIdFromSessions < ActiveRecord::Migration[4.2]
  def up
    remove_column :sessions, :user_id
  end

  def down
    add_column :sessions, :user_id, :integer
  end
end
