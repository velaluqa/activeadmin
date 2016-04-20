class AddVisitDataToVisits < ActiveRecord::Migration
  def change
    add_column :visits, :assigned_image_series_index, :jsonb, null: false, default: {}
    add_column :visits, :required_series, :jsonb, null: false, default: {}
    add_column :visits, :mqc_results, :jsonb, null: false, default: {}
    add_column :visits, :mqc_comment, :string
    add_column :visits, :mqc_version, :string

    add_index :visits, :assigned_image_series_index, using: :gin
    add_index :visits, :required_series, using: :gin
    add_index :visits, :mqc_results, using: :gin
  end
end
