class AddDominoUnidToCenters < ActiveRecord::Migration
  def change
    add_column :centers, :domino_unid, :string
  end
end
