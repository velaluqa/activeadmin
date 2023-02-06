# ## Schema Information
#
# Table name: `required_series`
#
# ### Columns
#
# Name                   | Type               | Attributes
# ---------------------- | ------------------ | ---------------------------
# **`created_at`**       | `datetime`         | `not null`
# **`domino_unid`**      | `string`           |
# **`id`**               | `integer`          | `not null, primary key`
# **`image_series_id`**  | `integer`          |
# **`name`**             | `string`           | `not null`
# **`tqc_comment`**      | `text`             |
# **`tqc_date`**         | `datetime`         |
# **`tqc_results`**      | `jsonb`            |
# **`tqc_state`**        | `integer`          |
# **`tqc_user_id`**      | `integer`          |
# **`tqc_version`**      | `string`           |
# **`updated_at`**       | `datetime`         | `not null`
# **`visit_id`**         | `integer`          | `not null`
#
# ### Indexes
#
# * `index_required_series_on_image_series_id`:
#     * **`image_series_id`**
# * `index_required_series_on_visit_id_and_name` (_unique_):
#     * **`visit_id`**
#     * **`name`**
#
class RequiredSeries < ApplicationRecord
  include DominoDocument

  belongs_to :visit
  belongs_to :image_series, optional: true
  belongs_to :tqc_user, class_name: 'User', optional: true

  after_save :update_image_series_state
  after_commit :schedule_domino_sync

  has_paper_trail(
    versions: {
      class_name: 'Version',
    },
    meta: {
      study_id: ->(series) { series.study.andand.id }
    }
  )

  scope :join_study, -> { joins(visit: { patient: { center: :study } }) }

  scope :searchable, -> { join_study.select(<<SELECT.strip_heredoc) }
    studies.id AS study_id,
    studies.name AS study_name,
    centers.code ||
    patients.subject_id ||
    '#' ||
    visits.visit_number ||
    CASE WHEN visits.repeatable_count > 0 THEN ('.' || visits.repeatable_count) ELSE '' END ||
    ' - ' || required_series.name
    AS text,
    required_series.id::varchar AS result_id,
    'RequiredSeries'::varchar AS result_type
SELECT

  include ScopablePermissions

  def self.with_permissions
    join_study.joins(<<JOIN.strip_heredoc)
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

  def self.count_for_study(study_id)
    join_study
      .where(studies: { id: study_id })
      .count
  end

  def self.grouped_count_for_study(study_id, group_by)
    join_study
      .where(studies: { id: study_id })
      .group("\"required_series\".\"#{group_by}\"")
      .count
      .map { |group, count| [tqc_states.key(group) || 'unassigned', count] }
      .to_h
  end

  enum(tqc_state: { pending: 0, issues: 1, passed: 2 })

  def study
    visit.andand.study
  end

  def assigned?
    image_series_id.present?
  end

  def missing?
    image_series_id.blank?
  end

  def assigned_image_series
    return nil if image_series_id.nil?
    @assigned_required_series ||= ImageSeries.where(
      id: image_series_id,
      visit_id: visit_id
    ).first
  end

  # Returns the studies tqc specification of the required series.
  #
  # @param version [Symbol, String] which version to get
  # @return [Array] the tqc spec for the required series
  def tqc_spec(version: nil)
    return [] unless study.semantically_valid?(version: version)

    required_series_spec = visit.required_series_spec(version: version)[name]
    return [] unless required_series_spec.is_a?(Hash)

    required_series_spec['tqc']
  end

  def tqc_spec_with_results(version: nil)
    return nil if tqc_results.nil?
    tqc_spec(version: version).each do |question|
      question['answer'] = tqc_results[question['id']]
    end
  end

  def image_storage_path
    "#{visit.image_storage_path}/#{name}"
  end

  def assign_image_series!(new_series)
    return if new_series.id == image_series_id
    ActiveRecord::Base.transaction do
      self.image_series = new_series
      reset_tqc_attributes
      save!
      update_image_storage!
    end
  end

  def unassign_image_series!
    ActiveRecord::Base.transaction do
      self.image_series = nil
      reset_tqc_attributes
      save!
      update_image_storage!
    end
  end

  def reset_tqc!
    reset_tqc_attributes
    save!
  end

  def set_tqc_result(result, user, comment, date = nil, version = nil)
    required_series_spec = visit.required_series_spec
    return 'No valid study configuration exists.' if required_series_spec.nil?
    tqc_spec = required_series_spec[name].andand['tqc']
    return 'No tQC config for this required series exists.' if tqc_spec.nil?
    return 'No assignment for this required series exists.' if missing?

    all_passed = tqc_spec.all? { |spec| result[spec['id']] == true }

    self.tqc_state = (all_passed ? 'passed' : 'issues')
    self.tqc_user_id = (user.is_a?(User) ? user.id : user)
    self.tqc_date = (date.nil? ? Time.now : date)
    self.tqc_version = (version.nil? ? study.locked_version : version)
    self.tqc_results = result
    self.tqc_comment = comment
    save!
  end

  def wado_query
    return nil unless assigned?
    {
      id: "#{visit.id}_#{name}",
      name: name,
      images: assigned_image_series.images.order(id: :asc)
    }
  end

  def domino_document_form
    'RequiredSeries'
  end

  def domino_document_query
    {
      'docCode' => 10_044,
      'ericaID' => visit.id,
      'RequiredSeries' => name
    }
  end

  def domino_document_properties(_action = :update)
    properties = {
      'ericaID' => visit.id,
      'CenterNo' => visit.patient.center.code,
      'PatNo' => visit.patient.domino_patient_no,
      'VisitNo' => visit.visit_number,
      'RequiredSeries' => name
    }

    if assigned_image_series.nil?
      properties.merge!(
        'trash' => 1,
        'ericaASID' => nil,
        'DateImaging' => {
          'data' => '01-01-0001',
          'type' => 'datetime'
        },
        'SeriesDescription' => nil,
        'DICOMTagNames' => nil,
        'DICOMValues' => nil
      )
    else
      properties.merge!(
        'trash' => 0,
        'ericaASID' => assigned_image_series.id,
        'DateImaging' => {
          'data' => assigned_image_series.imaging_date.strftime('%d-%m-%Y'),
          'type' => 'datetime'
        },
        'SeriesDescription' => assigned_image_series.name
      )
      properties.merge!(assigned_image_series.dicom_metadata_to_domino)
    end

    properties.merge(tqc_to_domino)
  end

  def domino_sync
    ensure_domino_document_exists
  end

  def versions_item_name
    "#{visit.name} #{name}"
  end

  protected

  def tqc_to_domino
    result = {
      'QCdate' => {
        'data' => (tqc_date.nil? ? '01-01-0001' : tqc_date.strftime('%d-%m-%Y')),
        'type' => 'datetime'
      },
      'QCresult' => tqc_state_label,
      'QCcomment' => tqc_comment,
      'QCperson' => (tqc_user.nil? ? nil : tqc_user.name),
      'QCCriteriaNames' => nil,
      'QCValues' => nil
    }

    results = tqc_spec_with_results(version: (tqc_version || study.locked_version))
    if results.present?
      criteria_names = []
      criteria_values = []
      results.each do |criterion|
        criteria_names << criterion['label']
        criteria_values << (criterion['answer'] == true ? 'Pass' : 'Fail')
      end
      result['QCCriteriaNames'] = criteria_names.join("\n")
      result['QCValues'] = criteria_values.join("\n")
    end
    result
  end

  def tqc_state_label
    case tqc_state
    when 'pending' then 'Pending'
    when 'issues' then 'Performed, issues present'
    when 'passed' then 'Performed, no issues present'
    end
  end

  def has_dicom?
    image_series.has_dicom?
  end

  private

  # TODO: Refactor into Operation
  def update_image_series_state
    return unless saved_change_to_image_series_id?

    if image_series_id_before_last_save.blank? && image_series_id.present?
      ImageSeries.find(image_series_id).update(state: :required_series_assigned)
    elsif image_series_id_before_last_save.present? && image_series_id.present?
      ImageSeries.find(image_series_id).update(state: :required_series_assigned)
      image_series_before_last_save = ImageSeries.where(id: image_series_id_before_last_save).first
      return if image_series_before_last_save.nil?
      if RequiredSeries.where(visit: visit, image_series_id: image_series_id_before_last_save).where.not(name: name).exists?
        image_series_before_last_save.update(state: :required_series_assigned)
      else
        image_series_before_last_save.update(state: :visit_assigned)
      end
    elsif image_series_id_before_last_save.present? && image_series_id.blank?
      image_series_before_last_save = ImageSeries.where(id: image_series_id_before_last_save).first 
      return if image_series_before_last_save.nil?
      if RequiredSeries.where(visit: visit, image_series_id: image_series_id_before_last_save).where.not(name: name).exists?
        image_series_before_last_save.update(state: :required_series_assigned)
      else
        image_series_before_last_save.update(state: :visit_assigned)
      end
    end
  end

  def reset_tqc_attributes
    self.tqc_state = (missing? ? nil : :pending)
    self.tqc_user_id = nil
    self.tqc_date = nil
    self.tqc_version = nil
    self.tqc_results = nil
    self.tqc_comment = nil
  end

  def update_image_storage!
    FileUtils.rm(ERICA.image_storage_path.join(image_storage_path), force: true)
    return if missing?
    FileUtils.ln_sf(image_series.id.to_s, ERICA.image_storage_path.join(image_storage_path))
  end

  def self.classify_audit_trail_event(c)
    c.delete('domino_unid')

    return if c.empty?

    if %w[issues passed].include?(c["tqc_state"].andand[1]) && c['tqc_user_id'] && c['tqc_user_id'][1].present? && c['tqc_date'] && c['tqc_date'][1].present?
      :tqc_performed
    elsif c["tqc_state"].andand[1] == "pending" && c['tqc_user_id'] && c['tqc_user_id'][1].blank? && c['tqc_date'] && c['tqc_date'][1].blank?
      :tqc_reset
    elsif c["image_series_id"] && c["image_series_id"][1].present?
      :series_assigned
    elsif c["image_series_id"] && c["image_series_id"][1].blank?
      :series_unassigned
    end
  end

  def self.audit_trail_event_title_and_severity(event_symbol)
    case event_symbol
    when :tqc_performed then ['TQC Performed', :ok]
    when :series_assigned then ['Image Series Assigned', :ok]
    when :tqc_reset then ['TQC Reset', :warning]
    when :series_unassigned then ['Image Series Unassigned', :warning]
    end
  end
end
