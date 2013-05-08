class AddCodeToCenters < ActiveRecord::Migration
  def change
    add_column :centers, :code, :string
  end
end
