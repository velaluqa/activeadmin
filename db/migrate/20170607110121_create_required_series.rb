class CreateRequiredSeries < ActiveRecord::Migration
  def change
    create_table :required_series do |t|
      t.references :visit, null: false
      t.string :name, null: false
      t.references :image_series, null: true
      t.integer :tqc_state, null: true
      t.datetime :tqc_date, null: true
      t.string :tqc_version, null: true
      t.jsonb :tqc_results, null: true
      t.integer :tqc_user_id, null: true
      t.text :tqc_comment, null: true
      t.string :domino_unid, null: true
      t.timestamps(null: false)
    end
    add_index :required_series, :image_series_id
    add_index :required_series, [:visit_id, :name], unique: true
  end
end
