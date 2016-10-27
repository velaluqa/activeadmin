class ChangeNotificationProfileHabtmAssociationsToHasManyThrough < ActiveRecord::Migration
  def up
    create_table :notification_profile_users do |t|
      t.references :notification_profile, null: false
      t.references :user, null: false
    end
    # This enforces uniqueness and speeds up profile->user lookups.
    add_index(:notification_profile_users, [:notification_profile_id, :user_id],
              unique: true,
              name: 'index_notification_profile_users_join_table_index')
    # This speeds up user->profile lookups
    add_index(:notification_profile_users, :user_id)

    assocs = ActiveRecord::Base.connection.execute('SELECT * FROM notification_profiles_users').to_a
    assocs.each do |assoc|
      NotificationProfileUser.create(
        notification_profile_id: assoc['notification_profile_id'].to_i,
        user_id: assoc['user_id'].to_i
      )
    end

    create_table :notification_profile_roles do |t|
      t.references :notification_profile, null: false
      t.references :role, null: false
    end
    # This enforces uniqueness and speeds up profile->role lookups.
    add_index(:notification_profile_roles, [:notification_profile_id, :role_id],
              unique: true,
              name: 'index_notification_profile_roles_join_table_index')
    # This speeds up role->profile lookups
    add_index(:notification_profile_roles, :role_id)

    assocs = ActiveRecord::Base.connection.execute('SELECT * FROM notification_profiles_roles').to_a
    assocs.each do |assoc|
      NotificationProfileRole.create(
        notification_profile_id: assoc['notification_profile_id'].to_i,
        role_id: assoc['role_id'].to_i
      )
    end

    drop_table :notification_profiles_users
    drop_table :notification_profiles_roles
  end

  def down
    create_table :notification_profiles_users, id: false do |t|
      t.references :notification_profile, null: false
      t.references :user, null: false
    end
    # This enforces uniqueness and speeds up profile->user lookups.
    add_index(:notification_profiles_users, [:notification_profile_id, :user_id],
              unique: true,
              name: 'index_notification_profiles_users_join_table_index')
    # This speeds up user->profile lookups
    add_index(:notification_profiles_users, :user_id)

    assocs = ActiveRecord::Base.connection.execute('SELECT * FROM notification_profile_users').to_a
    assocs.each do |assoc|
      ActiveRecord::Base.connection.
        execute(<<QUERY)
INSERT INTO notification_profiles_users (notification_profile_id, user_id) 
VALUES (#{assoc['notification_profile_id']}, #{assoc['user_id']});
QUERY
    end

    create_table :notification_profiles_roles, id: false do |t|
      t.references :notification_profile, null: false
      t.references :role, null: false
    end
    # This enforces uniqueness and speeds up profile->role lookups.
    add_index(:notification_profiles_roles, [:notification_profile_id, :role_id],
              unique: true,
              name: 'index_notification_profiles_roles_join_table_index')
    # This speeds up role->profile lookups
    add_index(:notification_profiles_roles, :role_id)

    assocs = ActiveRecord::Base.connection.execute('SELECT * FROM notification_profile_roles').to_a
    assocs.each do |assoc|
      ActiveRecord::Base.connection.
        execute(<<QUERY)
INSERT INTO notification_profiles_roles (notification_profile_id, role_id) 
VALUES (#{assoc['notification_profile_id']}, #{assoc['role_id']});
QUERY
    end

    Version.where(item_type: 'NotificationProfileUser').destroy_all
    Version.where(item_type: 'NotificationProfileRole').destroy_all

    drop_table :notification_profile_users
    drop_table :notification_profile_roles
  end
end
