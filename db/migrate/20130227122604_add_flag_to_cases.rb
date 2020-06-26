class AddFlagToCases < ActiveRecord::Migration[4.2]
  def change
    add_column :cases, :flag, :integer, default: 0
  end
end
