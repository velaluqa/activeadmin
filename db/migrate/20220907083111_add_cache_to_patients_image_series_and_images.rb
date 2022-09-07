class AddCacheToPatientsImageSeriesAndImages < ActiveRecord::Migration[5.2]
  def change
    add_column :patients, :cache, :jsonb, default: {}, null: false
    add_column :image_series, :cache, :jsonb, default: {}, null: false
    add_column :images, :cache, :jsonb, default: {}, null: false
  end
end
