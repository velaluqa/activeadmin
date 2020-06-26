class AddDominoUnidToPatients < ActiveRecord::Migration[4.2]
  def change
    add_column :patients, :domino_unid, :string
  end
end
