class AddItemNameToVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :versions, :item_name, :string
  end
end
  