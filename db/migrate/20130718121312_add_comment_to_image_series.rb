class AddCommentToImageSeries < ActiveRecord::Migration[4.2]
  def change
    add_column :image_series, :comment, :string
  end
end
