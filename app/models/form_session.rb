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

class FormSession < ApplicationRecord
  has_paper_trail(class_name: 'Version',)

  has_many(:form_answers)

  validates :name, presence: true, length: { minimum: 4 }, uniqueness: true

  accepts_nested_attributes_for :form_answers, allow_destroy: false

  scope :startable_by, ->(user) { where(id: FormAnswer.with_session.answerable_by(user).select(:form_session_id)) }
end
