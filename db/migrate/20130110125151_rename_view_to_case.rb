class RenameViewToCase < ActiveRecord::Migration[4.2]
  def change
    rename_table :views, :cases
  end
end
