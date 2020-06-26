class AddDominoServerNameToStudy < ActiveRecord::Migration[4.2]
  def change
    add_column :studies, :domino_server_name, :string
  end
end
