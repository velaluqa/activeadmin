class AddCommentToImageSeries < ActiveRecord::Migration
  def change
    add_column :image_series, :comment, :string
  end
end
