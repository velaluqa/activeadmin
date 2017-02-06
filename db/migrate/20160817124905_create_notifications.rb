class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :notification_profile, null: false
      t.references :resource, polymorphic: true, index: true, null: false
      t.references :version, index: true, null: true
      t.references :user, index: true, null: false
      t.datetime :email_sent_at, null: true # is set after mail was sent
      t.datetime :marked_seen_at, null: true # needs to be set manually
      t.timestamps :null => true
    end
  end
end
