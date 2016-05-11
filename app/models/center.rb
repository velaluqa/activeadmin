require 'domino_document_mixin'

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

  has_paper_trail
  acts_as_taggable

  attr_accessible :name, :study, :code, :domino_unid
  attr_accessible :study_id

  belongs_to :study
  has_many :patients

  scope :by_study_ids, lambda { |*ids|
    where(study_id: Array[ids].flatten)
  }

  include ScopablePermissions

  def self.with_permissions
    joins(<<JOIN)
INNER JOIN studies ON centers.study_id = studies.id
INNER JOIN user_roles ON
  (
       (user_roles.scope_object_type = 'Study'   AND user_roles.scope_object_id = studies.id)
    OR (user_roles.scope_object_type = 'Center'  AND user_roles.scope_object_id = centers.id)
    OR user_roles.scope_object_id IS NULL
  )
INNER JOIN roles ON user_roles.role_id = roles.id
INNER JOIN permissions ON roles.id = permissions.role_id
JOIN
  end

  validates_uniqueness_of :name, :scope => :study_id
  validates_uniqueness_of :code, :scope => :study_id
  validates_presence_of :name, :code, :study_id

  before_destroy do
    unless patients.empty?
      errors.add :base, 'You cannot delete a center which has patients associated.' 
      return false
    end

    return true
  end

  before_save :ensure_study_is_unchanged

  def full_name
    self.code + ' - ' + self.name
  end
  
  def previous_image_storage_path
    if(self.previous_changes.include?(:study_id))
      previous_study = Study.find(self.previous_changes[:study_id][0])
      
      previous_study.image_storage_path + '/' + self.id.to_s
    else
      image_storage_path
    end
  end
  def image_storage_path
    self.study.image_storage_path + '/' + self.id.to_s
  end

  def wado_query
    self.patients.map {|patient| patient.wado_query}
  end

  def lotus_notes_url
    self.study.notes_links_base_uri + self.domino_unid unless (self.domino_unid.nil? or self.study.nil? or self.study.notes_links_base_uri.nil?)
  end
  def domino_document_form
    'Center'
  end
  def domino_document_query
    {'docCode' => 10005, 'CenterNo' => self.code}
  end
  def domino_document_fields
    ['id', 'code', 'name']
  end
  def domino_document_properties(action = :update)
    {
      'ericaID' => self.id,
      'CenterNo' => self.code,
    }.merge!(action == :create ? {'CenterShortName' => self.name} : {})    
  end
  def domino_sync
    self.ensure_domino_document_exists
  end

  def self.classify_audit_trail_event(c)
    # ignore Domino UNID changes that happened along with a property change
    c.delete('domino_unid')

    if(c.keys == ['name'])
      :name_change
    elsif(c.keys == ['study_id'])
      :study_change
    elsif(c.keys == ['code'])
      :code_change
    end
  end
  def self.audit_trail_event_title_and_severity(event_symbol)
    return case event_symbol
           when :name_change then ['Name Change', :ok]
           when :study_change then ['Study Change', :warning]
           when :code_change then ['Center Code Change', :warning]
           end
  end

  protected
  
  def ensure_study_is_unchanged
    if(self.persisted? and self.study_id_changed?)
      errors[:study] << 'A center cannot be reassigned to a different study.'
      return false
    end

    return true
  end
end
