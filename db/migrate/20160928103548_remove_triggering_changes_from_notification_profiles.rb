class RemoveTriggeringChangesFromNotificationProfiles < ActiveRecord::Migration[4.2]
  def change
    remove_column :notification_profiles, :triggering_changes, :jsonb, null: false, default: []
  end
end
