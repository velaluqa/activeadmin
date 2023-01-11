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

class Configuration < ApplicationRecord
  has_paper_trail(
    versions: {
      class_name: 'Version'
    },
    meta: {
      form_definition_id: ->(configuration) {
        configuration.configurable_id if configuration.configurable_type == "FormDefinition"
      },
      configuration_id: ->(configuration) { configuration.id }
    }
  )

  has_one(
    :form_definition,
    foreign_key: :current_configuration_id
  )
  belongs_to(
    :configurable,
    polymorphic: true
  )
  has_many(
    :form_answers,
    foreign_key: :configuration_id
  )

  belongs_to(
    :previous_configuration,
    class_name: "Configuration",
    optional: true
  )

  def versions_item_name
    "#{configurable_type}: #{configurable.name}"
  end

  def data
    JSON.parse(payload[0] == "{" ? payload : "{}")
  end

  def data=(data)
    self.payload = JSON.dump(data)
  end
end
