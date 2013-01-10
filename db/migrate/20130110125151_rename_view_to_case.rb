class RenameViewToCase < ActiveRecord::Migration
  def change
    rename_table :views, :cases
  end
end
