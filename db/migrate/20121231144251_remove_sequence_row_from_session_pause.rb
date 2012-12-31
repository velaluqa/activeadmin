class RemoveSequenceRowFromSessionPause < ActiveRecord::Migration
  def up
    remove_column :session_pauses, :sequence_row
  end

  def down
    add_column :session_pauses, :sequence_row, :integer
  end
end
