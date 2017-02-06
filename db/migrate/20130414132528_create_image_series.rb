class CreateImageSeries < ActiveRecord::Migration
  def change
    create_table :image_series do |t|
      t.string :name
      t.integer :visit_id

      t.timestamps :null => true
    end
  end
end
