class AddDominoUnidToImageSeries < ActiveRecord::Migration
  def change
    add_column :image_series, :domino_unid, :string
  end
end
