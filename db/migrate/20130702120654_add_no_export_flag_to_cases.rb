class AddNoExportFlagToCases < ActiveRecord::Migration[4.2]
  def change
    add_column :cases, :no_export, :boolean, default: false
  end
end
