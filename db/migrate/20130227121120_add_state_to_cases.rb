class AddStateToCases < ActiveRecord::Migration
  def change
    add_column :cases, :state, :integer, default: 0
  end
end
