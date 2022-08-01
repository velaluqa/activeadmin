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

FactoryBot.define do
  factory :historic_report_cache_entry do
    historic_report_query
    study
    date { DateTime.now }
  end
end
