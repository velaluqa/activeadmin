class CreateNotificationProfiles < ActiveRecord::Migration
  def change
    create_table :notification_profiles do |t|
      t.string :title, null: false
      t.text :description, null: true
      t.string :notification_type, null: true
      t.string :triggering_action, null: false, default: 'all'
      t.string :triggering_resource, null: false
      t.jsonb :triggering_changes, null: false, default: {}
      t.jsonb :filters, null: false, default: {}
      t.boolean :only_authorized_recipients, null: false, default: true
      t.boolean :is_active, default: false, null: false
      t.timestamps null: false
    end
  end
end
