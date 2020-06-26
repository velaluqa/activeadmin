class AddDominoUnidToCenters < ActiveRecord::Migration[4.2]
  def change
    add_column :centers, :domino_unid, :string
  end
end
