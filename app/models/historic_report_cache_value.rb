# ## Schema Information
#
# Table name: `historic_report_cache_values`
#
# ### Columns
#
# Name                                  | Type               | Attributes
# ------------------------------------- | ------------------ | ---------------------------
# **`count`**                           | `integer`          | `not null`
# **`delta`**                           | `integer`          | `not null`
# **`group`**                           | `string`           |
# **`historic_report_cache_entry_id`**  | `integer`          | `not null`
# **`id`**                              | `integer`          | `not null, primary key`
#
# ### Indexes
#
# * `index_historic_report_cache_values_on_entry_id`:
#     * **`historic_report_cache_entry_id`**
#
class HistoricReportCacheValue < ActiveRecord::Base
  belongs_to :historic_report_cache_entry

  def to_h
    { group: group, count: count, delta: delta }
  end
end
