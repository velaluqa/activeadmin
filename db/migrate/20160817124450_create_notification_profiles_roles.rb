class CreateNotificationProfilesRoles < ActiveRecord::Migration
  def change
    create_table :notification_profiles_roles, id: false do |t|
      t.references :notification_profile, null: false
      t.references :role, null: false
    end
    # This enforces uniqueness and speeds up apple->oranges lookups.
    add_index(:notification_profiles_roles, [:notification_profile_id, :role_id],
              unique: true,
              name: 'index_notification_profiles_roles_join_table_index')
    # This speeds up orange->apple lookups
    add_index(:notification_profiles_roles, :role_id)
  end
end
