class AddMigratedRequiredSeriesToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :migrated_required_series, :boolean, null: false, default: false, index: true
  end
end
