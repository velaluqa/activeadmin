class AddMigratedRequiredSeriesToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :migrated_required_series, :boolean, null: false, default: false, index: true
  end
end
