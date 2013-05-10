class AddDominoUnidToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :domino_unid, :string
  end
end
