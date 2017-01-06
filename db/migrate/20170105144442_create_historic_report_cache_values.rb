class CreateHistoricReportCacheValues < ActiveRecord::Migration
  def change
    create_table :historic_report_cache_values do |t|
      t.references :historic_report_cache_entry, null: false
      t.string :group, null: true
      t.integer :count, null: false
      t.integer :delta, null: false
    end
    add_index(
      :historic_report_cache_values,
      :historic_report_cache_entry_id,
      name: 'index_historic_report_cache_values_on_entry_id'
    )
  end
end
