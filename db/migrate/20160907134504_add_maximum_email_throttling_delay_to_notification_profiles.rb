class AddMaximumEmailThrottlingDelayToNotificationProfiles < ActiveRecord::Migration[4.2]
  def change
    add_column :notification_profiles, :maximum_email_throttling_delay, :integer
  end
end
