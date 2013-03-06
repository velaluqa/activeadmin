class AddExportedAtToCases < ActiveRecord::Migration
  def change
    add_column :cases, :exported_at, :datetime
  end
end
