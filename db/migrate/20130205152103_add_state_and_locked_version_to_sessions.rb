class AddStateAndLockedVersionToSessions < ActiveRecord::Migration
  def change
    add_column :sessions, :state, :integer, default: 0
    add_column :sessions, :locked_version, :string
  end
end
