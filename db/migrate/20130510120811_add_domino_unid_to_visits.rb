class AddDominoUnidToVisits < ActiveRecord::Migration
  def change
    add_column :visits, :domino_unid, :string
  end
end
