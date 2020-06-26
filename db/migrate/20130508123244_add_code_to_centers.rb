class AddCodeToCenters < ActiveRecord::Migration[4.2]
  def change
    add_column :centers, :code, :string
  end
end
