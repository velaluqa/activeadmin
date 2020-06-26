class AddVersionToForm < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :version, :int
  end
end
