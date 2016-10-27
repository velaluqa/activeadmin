class ChangeDefaultOfNotificationProfilesFilters < ActiveRecord::Migration
  def change
    change_column :notification_profiles, :filters, :jsonb, default: []
  end
end
