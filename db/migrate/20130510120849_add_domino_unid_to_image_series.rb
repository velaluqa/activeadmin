class AddDominoUnidToImageSeries < ActiveRecord::Migration[4.2]
  def change
    add_column :image_series, :domino_unid, :string
  end
end
