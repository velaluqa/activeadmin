class AddExportedAtToCases < ActiveRecord::Migration[4.2]
  def change
    add_column :cases, :exported_at, :datetime
  end
end
