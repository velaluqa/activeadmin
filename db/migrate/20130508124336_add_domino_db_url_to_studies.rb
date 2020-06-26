class AddDominoDbUrlToStudies < ActiveRecord::Migration[4.2]
  def change
    add_column :studies, :domino_db_url, :string
  end
end
