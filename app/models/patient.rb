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
class Patient < ApplicationRecord
  include DominoDocument

  has_paper_trail(
    class_name: 'Version',
    meta: {
      study_id: ->(patient) { patient.study.andand.id }
    }
  )
  acts_as_taggable

  attr_accessible(
    :center,
    :subject_id,
    :domino_unid,
    :center_id,
    :data,
    :export_history,
    :visit_template
  )

  belongs_to :center
  has_many :visits, dependent: :destroy
  has_many :image_series, dependent: :destroy

  has_many :user_roles, as: :scope_object, dependent: :destroy

  validates_uniqueness_of :subject_id, scope: :center_id
  validates_presence_of :subject_id
  validates_presence_of :center_id

  scope :by_study_ids, ->(*ids) {
    joins(:center)
      .where(centers: { study_id: Array[ids].flatten })
  }

  scope :searchable, -> { join_study.select(<<SELECT.strip_heredoc) }
    centers.study_id AS study_id,
    studies.name AS study_name,
    centers.code || patients.subject_id AS text,
    patients.id AS result_id,
    'Patient'::varchar AS result_type
SELECT

  scope :join_study, -> { joins(center: :study) }

  before_create :add_visits_from_template

  include ImageStorageCallbacks

  include ScopablePermissions

  def self.with_permissions
    joins(center: :study).joins(<<JOIN.strip_heredoc)
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

  scope :of_study, lambda { |study|
    study_id = study
    study_id = study.id if study.is_a?(ActiveRecord::Base)
    joins(:center).where(centers: { study_id: study_id })
  }

  before_save :ensure_study_is_unchanged

  def form_answers
    FormAnswer.where(patient_id: id)
  end

  def study
    center.andand.study
  end

  # virtual attribute for pretty names
  def name
    if center.nil?
      subject_id
    else
      center.code + subject_id
    end
  end

  def next_series_number
    return 1 if image_series.empty?
    image_series.order('series_number DESC').first.series_number + 1
  end

  def image_storage_path
    "#{center.image_storage_path}/#{id}"
  end

  def wado_query
    { id: id, name: name, visits: visits.map(&:wado_query) +
      [{ id: 0, name: 'Unassigned', image_series: image_series.where(visit_id: nil).map(&:wado_query) }] }
  end

  # Used as getter by ActiveAdmin form.
  #
  # @return [String] visit template to set upon save
  attr_reader :visit_template

  # Used as setter by ActiveAdmin form.
  #
  # @param [String] visit template to create visits from upon save
  attr_writer :visit_template

  def domino_patient_no
    "#{center.code}#{subject_id}"
  end
  alias_method :domino_patient_number, :domino_patient_no
  def domino_document_form
    'TrialSubject'
  end

  def domino_document_query
    {
      'docCode' => 10_028,
      'CenterNo' => center.code,
      'PatientNo' => domino_patient_no
    }
  end

  def domino_document_fields
    %w[id subject_id]
  end

  def domino_document_properties(_action = :update)
    return {} if center.nil?

    {
      'ericaID' => id,
      'Center' => center.name,
      'shCenter' => center.name,
      'CenterNo' => center.code,
      'shCenterNo' => center.code,
      'UIDCenter' => center.domino_unid,
      'PatientNo' => domino_patient_no
    }
  end

  def domino_sync
    ensure_domino_document_exists
  end

  def to_s
    name
  end

  def visit_template_applicable?(template)
    (template = study.visit_templates[template]) || (return false)
    return true if template['repeatable']
    existing_visits_numbers = visits.map(&:original_visit_number)
    new_visit_numbers = template['visits'].map { |visit| visit['number'] }
    existing_visits_numbers & new_visit_numbers == []
  end

  def create_visits_from_template!(template)
    (template = study.visit_templates[template]) || (return false)
    Visit.transaction do
      template['visits'].each do |visit|
        max = visits
              .where(visit_number: visit['number'])
              .maximum(:repeatable_count) || -1
        postfix = (max > -1 ? ".#{max + 1}" : '')
        visits << Visit.create!(
          visit_number: "#{visit['number']}#{postfix}",
          visit_type: visit['type'],
          description: visit['description'],
          patient: self
        )
      end
    end
  end

  protected

  def ensure_study_is_unchanged
    if center_id_changed? && !center_id_was.nil?
      old_center = Center.find(center_id_was)

      if old_center.study != center.study
        errors[:center] << 'A patient cannot be reassigned to a center in a different study.'
        return false
      end
    end

    true
  end

  # When a visit template is set at create, all visits from the
  # template are created.
  def add_visits_from_template
    (template = visit_template_hash) || return
    self.visits = template['visits'].map do |visit|
      Visit.new(
        visit_type: visit['type'],
        visit_number: visit['number'],
        description: visit['description']
      )
    end
  end

  def visit_template_hash
    enforced_template = study.visit_templates.find { |_name, tpl| tpl['create_patient_enforce'] }
    return enforced_template.second if enforced_template
    study.visit_templates[visit_template]
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
