# ## Schema Information
#
# Table name: `patients`
#
# ### Columns
#
# Name                  | Type               | Attributes
# --------------------- | ------------------ | ---------------------------
# **`center_id`**       | `integer`          |
# **`created_at`**      | `datetime`         |
# **`data`**            | `jsonb`            | `not null`
# **`domino_unid`**     | `string`           |
# **`export_history`**  | `jsonb`            | `not null`
# **`id`**              | `integer`          | `not null, primary key`
# **`images_folder`**   | `string`           |
# **`subject_id`**      | `string`           |
# **`updated_at`**      | `datetime`         |
#
# ### Indexes
#
# * `index_patients_on_center_id`:
#     * **`center_id`**
#
class Patient < ActiveRecord::Base
  include NotificationObservable
  include DominoDocument

  has_paper_trail class_name: 'Version'
  acts_as_taggable

  attr_accessible :center, :subject_id, :domino_unid
  attr_accessible :center_id, :data, :export_history

  belongs_to :center
  has_many :visits, :dependent => :destroy
  has_many :image_series, :dependent => :destroy

  has_many :user_roles, :as => :scope_object, dependent: :destroy

  validates_uniqueness_of :subject_id, :scope => :center_id
  validates_presence_of :subject_id
  validates_presence_of :center_id

  scope :by_study_ids, lambda { |*ids|
    joins(:center)
      .where(centers: { study_id: Array[ids].flatten })
  }

  scope :searchable, -> { joins(:center).select(<<SELECT) }
centers.study_id AS study_id,
centers.code || patients.subject_id AS text,
patients.id AS result_id,
'Patient' AS result_type
SELECT

  scope :join_study, -> { joins(center: :study) }

  include ImageStorageCallbacks

  include ScopablePermissions

  def self.with_permissions
    joins(center: :study).joins(<<JOIN)
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

  before_save :ensure_study_is_unchanged

  def form_answers
    return FormAnswer.where(:patient_id => self.id)
  end

  def study
    if self.center.nil?
      nil
    else
      self.center.study
    end
  end

  # virtual attribute for pretty names
  def name
    if(center.nil?)
      subject_id
    else
      center.code + subject_id
    end
  end

  def next_series_number
    return 1 if self.image_series.empty?
    image_series.order('series_number DESC').first.series_number + 1
  end
  def image_storage_path
    "#{center.image_storage_path}/#{id}"
  end

  def wado_query
    {:id => self.id, :name => self.name, :visits => self.visits.map {|visit| visit.wado_query} +
      [{:id => 0, :name => 'Unassigned', :image_series => self.image_series.where(:visit_id => nil).map {|i_s| i_s.wado_query}
       }]
    }
  end

  def domino_patient_no
    "#{center.code}#{subject_id}"
  end
  alias_method :domino_patient_number, :domino_patient_no
  def domino_document_form
    'TrialSubject'
  end
  def domino_document_query
    {
      'docCode' => 10028,
      'CenterNo' => center.code,
      'PatientNo' => domino_patient_no,
    }
  end
  def domino_document_fields
    ['id', 'subject_id']
  end
  def domino_document_properties(action = :update)
    return {} if center.nil?

    {
      'ericaID' => id,
      'Center' => center.name,
      'shCenter' => center.name,
      'CenterNo' => center.code,
      'shCenterNo' => center.code,
      'UIDCenter' => center.domino_unid,
      'PatientNo' => domino_patient_no,
    }
  end
  def domino_sync
    self.ensure_domino_document_exists
  end

  def to_s
    name
  end

  protected

  def ensure_study_is_unchanged
    if(self.center_id_changed? and not self.center_id_was.nil?)
      old_center = Center.find(self.center_id_was)

      if(old_center.study != self.center.study)
        self.errors[:center] << 'A patient cannot be reassigned to a center in a different study.'
        return false
      end
    end

    return true
  end

  def self.classify_audit_trail_event(c)
    # ignore Domino UNID changes that happened along with a property change
    c.delete('domino_unid')

    if c.keys == ['subject_id']
      :name_change
    elsif c.keys == ['center_id']
      :center_change
    elsif c.keys == ['data']
      :data_change
    elsif c.keys == ['export_history']
      :export_to_ericav1
    end
  end

  def self.audit_trail_event_title_and_severity(event_symbol)
    case event_symbol
    when :name_change then ['Subject ID Change', :warning]
    when :center_change then ['Center Change', :warning]
    when :data_change then ['Patient Data Change', :ok]
    when :export_to_ericav1 then ['Export to ERICAV1', :ok]
    end
  end
end
