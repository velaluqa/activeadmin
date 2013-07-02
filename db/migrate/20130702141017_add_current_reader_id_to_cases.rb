class AddCurrentReaderIdToCases < ActiveRecord::Migration
  def change
    add_column :cases, :current_reader_id, :integer
  end
end
