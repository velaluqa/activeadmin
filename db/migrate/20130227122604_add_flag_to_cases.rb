class AddFlagToCases < ActiveRecord::Migration
  def change
    add_column :cases, :flag, :integer, default: 0
  end
end
