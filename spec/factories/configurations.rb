# ## Schema Information
#
# Table name: `configurations`
#
# ### Columns
#
# Name                             | Type               | Attributes
# -------------------------------- | ------------------ | ---------------------------
# **`configurable_id`**            | `uuid`             | `not null`
# **`configurable_type`**          | `string`           | `not null`
# **`created_at`**                 | `datetime`         | `not null`
# **`id`**                         | `uuid`             | `not null, primary key`
# **`payload`**                    | `text`             | `not null`
# **`previous_configuration_id`**  | `uuid`             |
# **`schema_spec`**                | `enum`             | `not null`
# **`updated_at`**                 | `datetime`         | `not null`
#
# ### Indexes
#
# * `index_configurations_on_configurable_id`:
#     * **`configurable_id`**
# * `index_configurations_on_previous_configuration_id`:
#     * **`previous_configuration_id`**
#

FactoryBot.define do
  factory :configuration do
    schema_spec { "formio_v1" }
    configurable { create(:form_definition) }
    payload { "{}" }
  end
end
