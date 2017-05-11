class CreateNotificationProfilesUsers < ActiveRecord::Migration
  def change
    create_table :notification_profiles_users, id: false do |t|
      t.references :notification_profile, null: false
      t.references :user, null: false
    end
    # This enforces uniqueness and speeds up apple->oranges lookups.
    add_index(:notification_profiles_users, %i[notification_profile_id user_id],
              unique: true,
              name: 'index_notification_profiles_users_join_table_index')
    # This speeds up orange->apple lookups
    add_index(:notification_profiles_users, :user_id)
  end
end
