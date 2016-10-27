class TransformNotificationProfileTriggeringActionToArray < ActiveRecord::Migration
  def up
    add_column :notification_profiles, :triggering_actions, :jsonb, null: false, default: []
    NotificationProfile.all.each do |profile|
      profile.triggering_actions = Array(profile.triggering_action)
    end
    remove_column :notification_profiles, :triggering_action
  end

  def down
    add_column :notification_profiles, :triggering_action, :string, null: false, default: 'all'
    NotificationProfile.all.each do |profile|
      profile.triggering_action = Array(profile.triggering_action).first || 'all'
    end
    remove_column :notification_profiles, :triggering_actions
  end
end
