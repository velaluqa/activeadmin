# ## Schema Information
#
# Table name: `form_sessions`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`created_at`**   | `datetime`         | `not null`
# **`description`**  | `string`           |
# **`id`**           | `bigint(8)`        | `not null, primary key`
# **`name`**         | `string`           | `not null`
# **`updated_at`**   | `datetime`         | `not null`
#
# ### Indexes
#
# * `index_form_sessions_on_name`:
#     * **`name`**
#

FactoryBot.define do
  factory :form_session do
    sequence(:name) { |n| puts n; "Test Session #{n}" }
    description { "" }
  end
end
