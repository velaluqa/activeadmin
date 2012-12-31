class AddLastViewToSessionPause < ActiveRecord::Migration
  def change
    add_column :session_pauses, :last_view_id, :integer
  end
end
