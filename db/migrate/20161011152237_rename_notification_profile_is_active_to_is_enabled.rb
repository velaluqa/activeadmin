class RenameNotificationProfileIsActiveToIsEnabled < ActiveRecord::Migration[4.2]
  def change
    rename_column :notification_profiles, :is_active, :is_enabled
  end
end
