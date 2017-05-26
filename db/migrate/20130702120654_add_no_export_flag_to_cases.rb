class AddNoExportFlagToCases < ActiveRecord::Migration
  def change
    add_column :cases, :no_export, :boolean, default: false
  end
end
