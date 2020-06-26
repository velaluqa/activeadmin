class CreateImages < ActiveRecord::Migration[4.2]
  def change
    create_table :images do |t|
      t.integer :image_series_id

      t.timestamps null: true
    end
  end
end
