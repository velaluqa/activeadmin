# ## Schema Information
#
# Table name: `required_series`
#
# ### Columns
#
# Name                   | Type               | Attributes
# ---------------------- | ------------------ | ---------------------------
# **`created_at`**       | `datetime`         | `not null`
# **`domino_unid`**      | `string`           |
# **`id`**               | `integer`          | `not null, primary key`
# **`image_series_id`**  | `integer`          |
# **`name`**             | `string`           | `not null`
# **`tqc_comment`**      | `text`             |
# **`tqc_date`**         | `datetime`         |
# **`tqc_results`**      | `jsonb`            |
# **`tqc_state`**        | `integer`          |
# **`tqc_user_id`**      | `integer`          |
# **`tqc_version`**      | `string`           |
# **`updated_at`**       | `datetime`         | `not null`
# **`visit_id`**         | `integer`          | `not null`
#
# ### Indexes
#
# * `index_required_series_on_image_series_id`:
#     * **`image_series_id`**
# * `index_required_series_on_visit_id_and_name` (_unique_):
#     * **`visit_id`**
#     * **`name`**
#

FactoryBot.define do
  factory :required_series do
    visit
    sequence(:name) { |n| "image_series#{n}" }
  end
end
