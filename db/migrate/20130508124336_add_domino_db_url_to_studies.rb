class AddDominoDbUrlToStudies < ActiveRecord::Migration
  def change
    add_column :studies, :domino_db_url, :string
  end
end
