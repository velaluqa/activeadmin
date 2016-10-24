class AddTriggeringActionToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :triggering_action, :string, null: false
  end
end
