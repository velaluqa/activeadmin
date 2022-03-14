class FormSession < ApplicationRecord
  has_many(:form_answers)

  validates :name, presence: true, length: { minimum: 4 }, uniqueness: true

  accepts_nested_attributes_for :form_answers, allow_destroy: false

  scope :startable_by, ->(user) { where(id: FormAnswer.with_session.answerable_by(user).select(:form_session_id)) }
end
