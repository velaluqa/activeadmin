class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.integer :image_series_id

      t.timestamps
    end
  end
end
