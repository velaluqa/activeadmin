class AddTqcPropertiesToImageSeries < ActiveRecord::Migration
  def change
    add_column :image_series, :tqc_version, :string
    add_column :image_series, :tqc_date, :datetime
    add_column :image_series, :tqc_user_id, :integer
    add_column :image_series, :state, :integer, default: 0
  end
end
