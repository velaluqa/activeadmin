class AddTriggeringActionToNotifications < ActiveRecord::Migration
  def up
    add_column :notifications, :triggering_action, :string
    Notification.all.each do |notification|
      notification.triggering_action = notification.version.event
      notification.save
    end
    change_column :notifications, :triggering_action, :string, null: false
  end

  def down
    remove_column :notifications, :triggering_action
  end
end
