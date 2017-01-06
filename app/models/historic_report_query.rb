# ## Schema Information
#
# Table name: `historic_report_queries`
#
# ### Columns
#
# Name                 | Type               | Attributes
# -------------------- | ------------------ | ---------------------------
# **`created_at`**     | `datetime`         | `not null`
# **`group_by`**       | `string`           |
# **`id`**             | `integer`          | `not null, primary key`
# **`resource_type`**  | `string`           |
# **`updated_at`**     | `datetime`         | `not null`
#
# Defines dashboard report queries for historic data.
#
# ERICA keeps all historic data in the audit trail. This data is
# extracted for reporting if available.
#
class HistoricReportQuery < ActiveRecord::Base
end
