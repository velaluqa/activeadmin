# ## Schema Information
#
# Table name: `versions`
#
# ### Columns
#
# Name                  | Type               | Attributes
# --------------------- | ------------------ | ---------------------------
# **`created_at`**      | `datetime`         |
# **`event`**           | `string`           | `not null`
# **`id`**              | `integer`          | `not null, primary key`
# **`item_id`**         | `integer`          | `not null`
# **`item_type`**       | `string`           | `not null`
# **`object`**          | `jsonb`            |
# **`object_changes`**  | `jsonb`            |
# **`whodunnit`**       | `string`           |
#
# ### Indexes
#
# * `index_versions_on_item_type_and_item_id`:
#     * **`item_type`**
#     * **`item_id`**
#
class Version < PaperTrail::Version
  has_many :notifications
end
