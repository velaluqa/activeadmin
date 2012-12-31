class AddTypeToView < ActiveRecord::Migration
  def change
    add_column :views, :type, :string
  end
end
