class AddFilterTriggeringUserToNotificationProfiles < ActiveRecord::Migration
  def change
    add_column :notification_profiles, :filter_triggering_user, :string, null: false, default: 'exclude'
  end
end
