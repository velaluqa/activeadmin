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
class EmailTemplate < ActiveRecord::Base
  has_paper_trail class_name: 'Version'
end
