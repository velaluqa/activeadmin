class RemoveTriggeringChangesFromNotificationProfiles < ActiveRecord::Migration
  def change
    remove_column :notification_profiles, :triggering_changes, :jsonb, null: false, default: []
  end
end
