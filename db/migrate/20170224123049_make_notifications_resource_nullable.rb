class MakeNotificationsResourceNullable < ActiveRecord::Migration[4.2]
  def change
    change_column :notifications, :resource_type, :string, null: true, default: nil
    change_column :notifications, :resource_id, :integer, null: true, default: nil
  end
end
