# ## Schema Information
#
# Table name: `centers`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`code`**         | `string`           |
# **`created_at`**   | `datetime`         |
# **`domino_unid`**  | `string`           |
# **`id`**           | `integer`          | `not null, primary key`
# **`name`**         | `string`           |
# **`study_id`**     | `integer`          |
# **`updated_at`**   | `datetime`         |
#
# ### Indexes
#
# * `index_centers_on_study_id`:
#     * **`study_id`**
# * `index_centers_on_study_id_and_code` (_unique_):
#     * **`study_id`**
#     * **`code`**
#
class Center < ActiveRecord::Base
  include DominoDocument

  has_paper_trail(
    class_name: 'Version',
    meta: {
      study_id: ->(center) { center.study.andand.id }
    }
  )
  acts_as_taggable

  attr_accessible(
    :name,
    :study,
    :code,
    :domino_unid,
    :study_id
  )

  belongs_to :study
  has_many :patients

  has_many :user_roles, as: :scope_object, dependent: :destroy

  scope :by_study_ids, ->(*ids) {
    where(study_id: Array[ids].flatten)
  }

  include ImageStorageCallbacks

  include ScopablePermissions

  def self.with_permissions
    joins(:study).joins(<<JOIN.strip_heredoc)
      LEFT JOIN "patients" ON "patients"."center_id" = "centers"."id"
      INNER JOIN user_roles ON
        (
             (user_roles.scope_object_type = 'Study'   AND user_roles.scope_object_id = studies.id)
          OR (user_roles.scope_object_type = 'Center'  AND user_roles.scope_object_id = centers.id)
          OR (user_roles.scope_object_type = 'Patient' AND user_roles.scope_object_id = patients.id)
          OR user_roles.scope_object_id IS NULL
        )
      INNER JOIN roles ON user_roles.role_id = roles.id
      INNER JOIN permissions ON roles.id = permissions.role_id
JOIN
  end

  scope :searchable, -> { joins(:study).select(<<SELECT.strip_heredoc) }
    centers.study_id AS study_id,
    studies.name AS study_name,
    centers.code || ' - ' || centers.name AS text,
    centers.id AS result_id,
    'Center'::varchar AS result_type
SELECT

  scope :of_study, ->(study) {
    study_id = study
    study_id = study.id if study.is_a?(ActiveRecord::Base)
    where(study_id: study_id)
  }

  validates_uniqueness_of :name, scope: :study_id
  validates_uniqueness_of :code, scope: :study_id
  validates_presence_of :name, :code, :study_id

  before_destroy do
    unless patients.empty?
      errors.add :base, 'You cannot delete a center which has patients associated.'
      return false
    end
  end

  before_save :ensure_study_is_unchanged

  def full_name
    "#{code} - #{name}"
  end

  def image_storage_path
    "#{study.image_storage_path}/#{id}"
  end

  def wado_query
    patients.map(&:wado_query)
  end

  def lotus_notes_url
    study.notes_links_base_uri + domino_unid unless domino_unid.nil? || study.nil? || study.notes_links_base_uri.nil?
  end

  def domino_document_form
    'Center'
  end

  def domino_document_query
    { 'docCode' => 10_005, 'CenterNo' => code }
  end

  def domino_document_fields
    %w[id code name]
  end

  def domino_document_properties(action = :update)
    hash = { 'ericaID' => id, 'CenterNo' => code }
    hash['CenterShortName'] = name if action == :create
    hash
  end

  def domino_sync
    ensure_domino_document_exists
  end

  def self.classify_audit_trail_event(c)
    # ignore Domino UNID changes that happened along with a property change
    c.delete('domino_unid')

    if c.keys == ['name']
      :name_change
    elsif c.keys == ['study_id']
      :study_change
    elsif c.keys == ['code']
      :code_change
    end
  end

  def self.audit_trail_event_title_and_severity(event_symbol)
    case event_symbol
    when :name_change then ['Name Change', :ok]
    when :study_change then ['Study Change', :warning]
    when :code_change then ['Center Code Change', :warning]
    end
  end

  def read_study_id
    read_attribute(:study_id)
  end

  protected

  def ensure_study_is_unchanged
    if persisted? && study_id_changed?
      errors[:study] << 'A center cannot be reassigned to a different study.'
      false
    end
  end
end
