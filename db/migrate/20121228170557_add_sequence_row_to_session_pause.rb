class AddSequenceRowToSessionPause < ActiveRecord::Migration
  def change
    add_column :session_pauses, :sequence_row, :integer
  end
end
