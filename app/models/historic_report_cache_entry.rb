# coding: utf-8

# ## Schema Information
#
# Table name: `historic_report_cache_entries`
#
# ### Columns
#
# Name                            | Type               | Attributes
# ------------------------------- | ------------------ | ---------------------------
# **`date`**                      | `datetime`         | `not null`
# **`historic_report_query_id`**  | `integer`          | `not null`
# **`id`**                        | `integer`          | `not null, primary key`
# **`study_id`**                  | `integer`          | `not null`
# **`version_id`**                | `integer`          |
#
# ### Indexes
#
# * `index_historic_report_cache_entries_on_date`:
#     * **`date`**
# * `index_historic_report_cache_entries_on_historic_report_query_id`:
#     * **`historic_report_query_id`**
# * `index_historic_report_cache_entries_on_study_id`:
#     * **`study_id`**
#
class HistoricReportCacheEntry < ApplicationRecord
  belongs_to :historic_report_query
  belongs_to :study

  has_many :historic_report_cache_values

  def values=(values)
    self.historic_report_cache_values = values.map do |value|
      HistoricReportCacheValue.new(
        group: value[:group],
        count: value[:count],
        delta: value[:delta]
      )
    end
  end

  def values
    historic_report_cache_values.map(&:to_h)
  end

  def self.ensure_cache_entry(query, study_id, version, values = [])
    HistoricReportCacheEntry
      .where(historic_report_query_id: query.id, study_id: study_id, version_id: version.id)
      .first_or_create(values: values, date: version.created_at)
  end
end
