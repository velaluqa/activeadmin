class AddFilterTriggeringUserToNotificationProfiles < ActiveRecord::Migration[4.2]
  def change
    add_column :notification_profiles, :filter_triggering_user, :string, null: false, default: 'exclude'
  end
end
