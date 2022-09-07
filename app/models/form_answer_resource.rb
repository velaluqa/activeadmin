# ## Schema Information
#
# Table name: `form_answer_resources`
#
# ### Columns
#
# Name                  | Type               | Attributes
# --------------------- | ------------------ | ---------------------------
# **`form_answer_id`**  | `uuid`             | `not null`
# **`id`**              | `bigint(8)`        | `not null, primary key`
# **`resource_id`**     | `string`           | `not null`
# **`resource_type`**   | `string`           | `not null`
#
# ### Indexes
#
# * `form_answer_resources_primary_key_index` (_unique_):
#     * **`form_answer_id`**
#     * **`resource_id`**
#     * **`resource_type`**
# * `form_answer_resources_resource_index`:
#     * **`resource_id`**
#     * **`resource_type`**
# * `index_form_answer_resources_on_form_answer_id`:
#     * **`form_answer_id`**
#

class FormAnswerResource < ApplicationRecord
  has_paper_trail(
    class_name: 'Version',
    meta: {
      form_definition_id: ->(resource) { resource.form_answer.form_definition.id },
      form_answer_id: ->(resource) { resource.form_answer.id },
      configuration_id: ->(resource) { resource.form_answer.configuration.id }
    }
  )

  belongs_to(:form_answer)
  belongs_to(:resource, polymorphic: true)

  validates(:resource_identifier, presence: true)

  validate :uniqueness_of_form_answer_resource

  scope :for, ->(resource) { where("resource_type = ? AND resource_id = ?", resource.class.to_s, resource.id.to_s) }

  def uniqueness_of_form_answer_resource
    return unless resource
    return unless other_form_answer_resources.for(resource).exists?

    errors.add(:resource_identifier, "cannot be assigned multiple times")
  end

  def attributes_with_resource
    attributes.merge(
      resource: resource.attributes,
      has_dicom: resource.has_dicom?
    )
  end

  # TODO: Extract into class method helper: attr_polymorphic_identifier :resource
  def resource_identifier
    return nil unless resource

    "#{resource_type}_#{resource_id}"
  end

  def resource_identifier=(identifier)
    return self.resource = nil unless identifier

    match = identifier.match(/^(?<type>.*)_(?<id>\d+)$/)
    return unless match

    self.resource_id = match[:id].to_i
    self.resource_type = match[:type].classify
  end

  def other_form_answer_resources
    scope = form_answer.form_answer_resources

    return scope if id.nil?

    scope.where.not(id: id)
  end
end
