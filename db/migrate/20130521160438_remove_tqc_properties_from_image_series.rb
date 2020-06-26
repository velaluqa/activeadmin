class RemoveTqcPropertiesFromImageSeries < ActiveRecord::Migration[4.2]
  def up
    remove_column :image_series, :tqc_version
    remove_column :image_series, :tqc_date
    remove_column :image_series, :tqc_user_id
  end

  def down
    add_column :image_series, :tqc_user_id, :integer
    add_column :image_series, :tqc_date, :datetime
    add_column :image_series, :tqc_version, :string
  end
end
