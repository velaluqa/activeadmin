class AddCurrentReaderIdToCases < ActiveRecord::Migration[4.2]
  def change
    add_column :cases, :current_reader_id, :integer
  end
end
