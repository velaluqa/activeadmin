class ChangeDefaultOfNotificationProfilesFilters < ActiveRecord::Migration[4.2]
  def change
    change_column :notification_profiles, :filters, :jsonb, default: []
  end
end
