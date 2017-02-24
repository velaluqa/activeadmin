class MakeNotificationsResourceNullable < ActiveRecord::Migration
  def change
    change_column :notifications, :resource_type, :string, null: true, default: nil
    change_column :notifications, :resource_id, :integer, null: true, default: nil
  end
end
