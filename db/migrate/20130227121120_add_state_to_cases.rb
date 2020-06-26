class AddStateToCases < ActiveRecord::Migration[4.2]
  def change
    add_column :cases, :state, :integer, default: 0
  end
end
