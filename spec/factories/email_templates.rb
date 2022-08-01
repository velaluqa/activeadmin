# ## Schema Information
#
# Table name: `email_templates`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`created_at`**  | `datetime`         | `not null`
# **`email_type`**  | `string`           | `not null`
# **`id`**          | `integer`          | `not null, primary key`
# **`name`**        | `string`           | `not null`
# **`template`**    | `text`             | `not null`
# **`updated_at`**  | `datetime`         | `not null`
#

FactoryBot.define do
  factory :email_template do
    sequence(:name) { |n| "Email Template #{n}" }
    email_type { 'NotificationProfile' }
    template { 'Some template' }
  end
end
