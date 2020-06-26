class AddDominoUnidToVisits < ActiveRecord::Migration[4.2]
  def change
    add_column :visits, :domino_unid, :string
  end
end
