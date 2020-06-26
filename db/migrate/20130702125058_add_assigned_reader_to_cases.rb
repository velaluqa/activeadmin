class AddAssignedReaderToCases < ActiveRecord::Migration[4.2]
  def change
    add_column :cases, :assigned_reader_id, :integer
  end
end
