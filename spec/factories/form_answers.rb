# ## Schema Information
#
# Table name: `form_answers`
#
# ### Columns
#
# Name                              | Type               | Attributes
# --------------------------------- | ------------------ | ---------------------------
# **`annotated_images`**            | `jsonb`            |
# **`annotated_images_signature`**  | `string`           |
# **`answers`**                     | `jsonb`            |
# **`answers_signature`**           | `string`           |
# **`blocked_at`**                  | `datetime`         |
# **`blocking_user_id`**            | `integer`          |
# **`configuration_id`**            | `uuid`             | `not null`
# **`created_at`**                  | `datetime`         | `not null`
# **`form_definition_id`**          | `uuid`             | `not null`
# **`form_display_type_id`**        | `integer`          |
# **`form_session_id`**             | `integer`          |
# **`id`**                          | `uuid`             | `not null, primary key`
# **`is_obsolete`**                 | `boolean`          | `default(FALSE), not null`
# **`is_test_data`**                | `boolean`          | `default(FALSE), not null`
# **`public_key_id`**               | `bigint(8)`        |
# **`published_at`**                | `datetime`         |
# **`sequence_number`**             | `integer`          | `default(0), not null`
# **`signed_at`**                   | `datetime`         |
# **`signing_reason`**              | `text`             |
# **`study_id`**                    | `integer`          |
# **`submitted_at`**                | `datetime`         |
# **`updated_at`**                  | `datetime`         | `not null`
# **`user_id`**                     | `integer`          |
#
# ### Indexes
#
# * `index_form_answers_on_configuration_id`:
#     * **`configuration_id`**
# * `index_form_answers_on_form_definition_id`:
#     * **`form_definition_id`**
# * `index_form_answers_on_public_key_id`:
#     * **`public_key_id`**
#

FactoryBot.define do
  factory :form_answer do
    form_definition
    configuration
    public_key
    is_test_data { false }
    is_obsolete { false }
  end
end
