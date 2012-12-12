class AddVersionToForm < ActiveRecord::Migration
  def change
    add_column :forms, :version, :int
  end
end
