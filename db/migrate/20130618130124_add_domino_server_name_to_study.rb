class AddDominoServerNameToStudy < ActiveRecord::Migration
  def change
    add_column :studies, :domino_server_name, :string
  end
end
