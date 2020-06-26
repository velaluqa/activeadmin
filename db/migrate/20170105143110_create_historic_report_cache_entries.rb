class CreateHistoricReportCacheEntries < ActiveRecord::Migration[4.2]
  def change
    create_table :historic_report_cache_entries do |t|
      t.references :historic_report_query, null: false, index: true
      t.references :study, null: false, index: true
      t.datetime :date, null: false, index: true
    end
  end
end
