class AddVersionIdToHistoricReportCacheEntry < ActiveRecord::Migration
  def change
    add_column :historic_report_cache_entries, :version_id, :integer, index: true
    HistoricReportCacheEntry.delete_all
    HistoricReportCacheValue.delete_all
  end
end
