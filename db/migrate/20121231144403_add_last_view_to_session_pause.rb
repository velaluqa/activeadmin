class AddLastViewToSessionPause < ActiveRecord::Migration[4.2]
  def change
    add_column :session_pauses, :last_view_id, :integer
  end
end
