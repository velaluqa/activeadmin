class AddTypeToView < ActiveRecord::Migration[4.2]
  def change
    add_column :views, :type, :string
  end
end
