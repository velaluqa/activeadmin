class RenameNotificationProfileIsActiveToIsEnabled < ActiveRecord::Migration
  def change
    rename_column :notification_profiles, :is_active, :is_enabled
  end
end
