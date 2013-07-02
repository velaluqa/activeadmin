class AddAssignedReaderToCases < ActiveRecord::Migration
  def change
    add_column :cases, :assigned_reader_id, :integer
  end
end
