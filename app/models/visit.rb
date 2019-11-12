require 'git_config_repository'
# ## Schema Information
#
# Table name: `visits`
#
# ### Columns
#
# Name                                   | Type               | Attributes
# -------------------------------------- | ------------------ | ---------------------------
# **`created_at`**                       | `datetime`         |
# **`description`**                      | `string`           |
# **`domino_unid`**                      | `string`           |
# **`id`**                               | `integer`          | `not null, primary key`
# **`mqc_comment`**                      | `string`           |
# **`mqc_date`**                         | `datetime`         |
# **`mqc_results`**                      | `jsonb`            | `not null`
# **`mqc_state`**                        | `integer`          | `default(0)`
# **`mqc_user_id`**                      | `integer`          |
# **`mqc_version`**                      | `string`           |
# **`old_assigned_image_series_index`**  | `jsonb`            | `not null`
# **`old_required_series`**              | `jsonb`            | `not null`
# **`patient_id`**                       | `integer`          |
# **`repeatable_count`**                 | `integer`          | `default(0), not null`
# **`state`**                            | `integer`          | `default(0)`
# **`updated_at`**                       | `datetime`         |
# **`visit_number`**                     | `integer`          |
# **`visit_type`**                       | `string`           |
#
# ### Indexes
#
# * `index_visits_on_mqc_results`:
#     * **`mqc_results`**
# * `index_visits_on_mqc_user_id`:
#     * **`mqc_user_id`**
# * `index_visits_on_old_assigned_image_series_index`:
#     * **`old_assigned_image_series_index`**
# * `index_visits_on_old_required_series`:
#     * **`old_required_series`**
# * `index_visits_on_patient_id`:
#     * **`patient_id`**
# * `index_visits_on_visit_number`:
#     * **`visit_number`**
#
class Visit < ApplicationRecord
  include DominoDocument
  include NotificationFilter

  has_paper_trail(
    class_name: 'Version',
    meta: {
      study_id: ->(visit) { visit.study.andand.id }
    }
  )
  acts_as_taggable

  attr_accessible(
    :patient_id,
    :visit_number,
    :description,
    :visit_type,
    :state,
    :domino_unid,
    :patient,
    :assigned_image_series_index,
    :required_series,
    :mqc_date,
    :mqc_user_id,
    :mqc_state,
    :mqc_user,
    :mqc_results
  )

  belongs_to :patient
  has_many :image_series, after_add: :schedule_domino_sync, after_remove: :schedule_domino_sync
  belongs_to :mqc_user, class_name: 'User', optional: true
  has_many :required_series, dependent: :destroy

  scope :by_study_ids, ->(*ids) {
    joins(patient: { center: :study })
      .where(studies: { id: Array[ids].flatten })
  }

  scope :with_state, ->(state) {
    index =
      case state
      when Integer then state
      else Visit::STATE_SYMS.index(state.to_sym)
      end
    where(state: index)
  }

  scope :searchable, -> { join_study.select(<<SELECT.strip_heredoc) }
    centers.study_id AS study_id,
    studies.name AS study_name,
    centers.code ||
    patients.subject_id ||
    '#' ||
    visits.visit_number ||
    CASE WHEN visits.repeatable_count > 0 THEN ('.' || visits.repeatable_count) ELSE '' END
    AS text,
    visits.id AS result_id,
    'Visit'::varchar AS result_type
SELECT

  validates_uniqueness_of :visit_number, scope: %i[patient_id repeatable_count]
  validates_presence_of :visit_number, :patient_id

  before_destroy do
    image_series.each do |is|
      is.visit = nil
      is.save
    end
  end

  before_save :ensure_study_is_unchanged

  after_save(:update_required_series_preset)

  include ImageStorageCallbacks
  include ScopablePermissions

  def self.with_permissions
    joins(patient: { center: :study }).joins(<<JOIN.strip_heredoc)
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

  # TODO: Replace with a less naive full-text search index
  scope :with_filter, ->(query) {
    return unless query

    words = query.split(' ')
    conditions = words.map { 'CONCAT(visit_number, visit_type) LIKE ?' }.join(' AND ')
    terms = words.map { |word| "%#{word}%" }

    where(conditions, *terms)
  }

  scope :join_study, -> { joins(patient: { center: :study }) }

  scope :join_required_series, -> {
    joins(<<JOIN_QUERY.strip_heredoc)
      JOIN json_each(visits.required_series::json) visits_required_series_hash ON true
      JOIN json_to_record(visits_required_series_hash.value) as visits_required_series(tqc_state int) ON true
JOIN_QUERY
  }

  scope :of_study, ->(study) {
    study_id = study
    study_id = study.id if study.is_a?(ActiveRecord::Base)
    joins(patient: :center).where(centers: { study_id: study_id })
  }

  def name
    "#{patient.andand.name}##{visit_number}"
  end

  def original_visit_number
    read_attribute(:visit_number)
  end

  def visit_number
    original_visit_number.to_s + (repeatable_count > 0 ? ".#{repeatable_count}" : '')
  end

  def visit_number=(visit_number)
    number, count = visit_number.to_s.split('.')
    self[:visit_number] = number
    self[:repeatable_count] = count || 0
  end

  def visit_date
    image_series.map(&:imaging_date).reject(&:nil?).min
  end

  def study
    patient.andand.study
  end

  STATE_SYMS = %i[incomplete_na complete_tqc_passed incomplete_queried complete_tqc_pending complete_tqc_issues].freeze
  MQC_STATE_SYMS = %i[pending issues passed].freeze

  def self.state_sym_to_int(sym)
    Visit::STATE_SYMS.index(sym)
  end

  def self.int_to_state_sym(sym)
    Visit::STATE_SYMS[sym]
  end

  def state
    return -1 if read_attribute(:state).nil?
    read_attribute(:state)
  end

  def state_sym
    return -1 if read_attribute(:state).nil?
    Visit::STATE_SYMS[read_attribute(:state)]
  end

  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = if sym.is_a? Integer
              sym
            else
              Visit::STATE_SYMS.index(sym)
            end

    if index.nil?
      throw 'Unsupported state'
      return
    end

    write_attribute(:state, index)
  end

  def self.mqc_state_sym_to_int(sym)
    Visit::MQC_STATE_SYMS.index(sym)
  end

  def self.int_to_mqc_state_sym(sym)
    Visit::MQC_STATE_SYMS[sym]
  end

  def mqc_state
    return -1 if read_attribute(:mqc_state).nil?
    read_attribute(:mqc_state)
  end

  def mqc_state_sym
    return -1 unless read_attribute(:mqc_state)
    MQC_STATE_SYMS[read_attribute(:mqc_state)]
  end

  def mqc_state=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = if sym.is_a? Integer
              sym
            else
              Visit::MQC_STATE_SYMS.index(sym)
            end

    if index.nil?
      throw 'Unsupported mQC state'
      return
    end

    write_attribute(:mqc_state, index)
  end

  def visit_type_valid?
    return false if visit_type.nil?
    study.visit_types.include?(visit_type)
  end

  def required_series_available?
    !(required_series_names || []).empty?
  end

  # Returns the studies specification of required series for the
  # visits `visit_type` as Hash.
  #
  # @param version [Symbol, String] which version to get (can be
  #   `:current`, `:locked` or a version reference)
  # @return [Hash]
  def required_series_spec(version: nil)
    return {} unless study.semantically_valid?
    study.required_series_spec(visit_type, version: version)
  end

  def required_series_names
    RequiredSeries.where(visit_id: id).pluck(:name)
  end

  def required_series_objects
    RequiredSeries.where(visit_id: id)
  end

  def required_series_assignment
    required_series_objects.map do |required_series|
      [required_series.name, required_series.image_series_id]
    end.to_h
  end

  def image_storage_path
    "#{patient.image_storage_path}/#{id}"
  end

  def required_series_image_storage_path(required_series_name)
    "#{image_storage_path}/#{required_series_name}"
  end

  def wado_query
    {
      id: id,
      name: "Visit No. #{visit_number}",
      image_series: image_series.map(&:wado_query)
    }
  end

  def required_series_wado_query
    {
      id: id,
      name: "Visit No. #{visit_number}",
      image_series: required_series_objects
        .select(&:assigned?)
        .map(&:wado_query)
        .reject(&:blank?)
    }
  end

  def domino_document_form
    'ImagingVisit_mqc'
  end

  def domino_document_query
    {
      'docCode' => 10_045,
      'ericaID' => id
    }
  end

  def domino_document_properties(_action = :update)
    properties = {
      'ericaID' => id,
      'CenterNo' => patient.center.code,
      'PatNo' => patient.domino_patient_no,
      'VisitNo' => visit_number,
      'visitDescription' => description
    }

    visit_date = self.visit_date
    unless visit_date.nil?
      properties['DateImaging'] = { 'data' => visit_date.strftime('%d-%m-%Y'), 'type' => 'datetime' }
    end

    properties.merge!(mqc_to_domino)

    properties['Status'] =
      case state_sym
      when :incomplete_na then 'Incomplete, not available'
      when :complete_tqc_passed then 'Complete, tQC of all series passed'
      when :incomplete_queried then 'Incomplete, queried'
      when :complete_tqc_pending then 'Complete, tQC not finished'
      when :complete_tqc_issues then 'Complete, tQC finished, not all series passed'
      end

    properties
  end

  def domino_sync
    ensure_domino_document_exists
  end

  def change_required_series_assignment(changed_assignments)
    ActiveRecord::Base.transaction do
      changed_assignments.each_pair do |required_series_name, series_id|
        required_series = RequiredSeries.find_by(visit: self, name: required_series_name)
        if series_id.present?
          series = ImageSeries.find(series_id)
          next if series.blank?
          required_series.assign_image_series!(series)
        else
          required_series.unassign_image_series!
        end
      end
    end
  end

  def reset_tqc_result(required_series_name)
    RequiredSeries
      .find_by(visit: self, name: required_series_name)
      .reset_tqc!
  end

  def set_tqc_result(required_series_name, result, user, comment, date = nil, version = nil)
    RequiredSeries
      .find_by(visit: self, name: required_series_name)
      .set_tqc_result(result, user, comment, date, version)
  end

  def set_mqc_result(result, mqc_user, mqc_comment, mqc_date = nil, mqc_version = nil)
    mqc_spec = locked_mqc_spec
    return 'No valid study configuration exists or it doesn\'t contain an mQC config for this visits visit type.' if mqc_spec.nil?

    all_passed = true
    mqc_spec.each do |spec|
      all_passed &&= (!result.nil? && result[spec['id']] == true)
    end

    self.mqc_state = all_passed ? :passed : :issues
    self.mqc_user_id = mqc_user.is_a?(User) ? mqc_user.id : mqc_user
    self.mqc_date = mqc_date || Time.now
    self.mqc_results = result
    self.mqc_comment = mqc_comment
    self.mqc_version = mqc_version || study.andand.locked_version

    save

    true
  end

  ##
  # If defined returns the mqc_version for this visit. Otherwise it
  # returns the locked version for the associated study.
  #
  # @return [String] The mqc version
  def mqc_version
    read_attribute(:mqc_version) || study.andand.locked_version
  end

  def mqc_spec
    mqc_spec_at_version(mqc_version || study.locked_version)
  end

  def locked_mqc_spec
    mqc_spec_at_version(study.locked_version)
  end

  def mqc_spec_at_version(version)
    config = study.configuration_at_version(version)
    return nil if config.nil? || config['visit_types'].nil? || config['visit_types'][visit_type].nil?

    config['visit_types'][visit_type]['mqc']
  end

  def locked_mqc_spec_with_results
    return nil if locked_mqc_spec.nil? || mqc_results.blank?

    locked_mqc_spec.each do |question|
      question['answer'] = mqc_results[question['id']]
    end

    locked_mqc_spec
  end

  def locked_mqc_spec_with_results
    mqc_spec_with_results_at_version(study.locked_version)
  end

  def mqc_spec_with_results_at_version(version)
    mqc_spec_version = mqc_spec_at_version(version)
    return nil if mqc_spec_version.nil? || mqc_results.blank?

    mqc_spec_version.each do |question|
      question['answer'] = mqc_results[question['id']]
    end

    mqc_spec_version
  end

  def self.classify_audit_trail_event(c)
    # ignore Domino UNID changes that happened along with a property change
    c.delete('domino_unid')

    return if c.empty?

    if c.keys == ['visit_number']
      :visit_number_change
    elsif c.keys == ['patient_id']
      :patient_change
    elsif c.keys == ['description']
      :description_change
    elsif c.keys == ['visit_type']
      :visit_type_change
    elsif c.keys == ['state']
      # handle obsolete mqc states in state
      case c['state'][1]
      when :mqc_passed
        :mqc_passed
      when :mqc_issues
        :mqc_issues
      else
        :state_change
      end
    elsif c.include?('mqc_state') && (c.keys - %w[mqc_state mqc_date mqc_user_id]).empty?
      case [int_to_mqc_state_sym(c['mqc_state'][0].to_i), c['mqc_state'][1]]
      when %i[passed pending], %i[issues pending] then :mqc_reset
      when %i[pending passed] then :mqc_passed
      when %i[pending issues] then :mqc_issues
      when %i[issues passed] then :mqc_passed
      when %i[passed issues] then :mqc_issues
      else :mqc_state_change
      end
    elsif c.include?('mqc_user_id') && c.include?('mqc_date') && c.keys.length == 2 &&
          c['mqc_user_id'][1].blank? && c['mqc_date'][1].blank?
      :mqc_reset
    elsif c.include?('state') && c.include?('mqc_date') && (2..3).cover?(c.keys.length)
      case c['state'][1]
      when :mqc_passed then :mqc_passed
      when :mqc_issues then :mqc_issues
      end
    elsif c.include?('required_series')
      diffs = {}
      c['required_series'][1].each do |rs, to|
        from = c['required_series'][0][rs] || {}
        diff = to.diff(from)

        diffs[rs] = diff
      end

      if c.keys == ['required_series']
        if diffs.all? { |_rs, diff| (diff.keys - ['domino_unid']).empty? }
          :rs_domino_unid_change
        elsif diffs.all? { |_rs, diff| (diff.keys - %w[domino_unid tqc_state tqc_results tqc_date tqc_version tqc_user_id tqc_comment]).empty? }
          :rs_tqc_performed
        end
      elsif (c.keys - %w[required_series assigned_image_series_index]).empty?
        if diffs.all? do |rs, diff|
             (diff.keys - %w[domino_unid image_series_id tqc_state tqc_results tqc_date tqc_version tqc_user_id tqc_comment]).empty? &&
             ((diff.keys & %w[tqc_results tqc_date tqc_version tqc_user_id tqc_comment]).empty? ||
              (
                (diff['tqc_state'].nil? || diff['tqc_state'] == 0) &&
                c['required_series'][1][rs]['tqc_results'].nil? &&
                c['required_series'][1][rs]['tqc_date'].nil? &&
                c['required_series'][1][rs]['tqc_version'].nil? &&
                c['required_series'][1][rs]['tqc_user_id'].nil? &&
                c['required_series'][1][rs]['tqc_comment'].nil?
              )
             )
           end
          :rs_assignment_change
        end
      end
    elsif (c.keys - %w[mqc_version mqc_results mqc_comment]).empty?
      :mqc_performed
    end
  end

  def self.audit_trail_event_title_and_severity(event_symbol)
    case event_symbol
    when :visit_number_change then ['Visit Number Change', :ok]
    when :patient_change then ['Patient Change', :warning]
    when :description_change then ['Description Change', :ok]
    when :visit_type_change then ['Visit Type Change', :warning]
    when :state_change then ['State Change', :warning]
    when :mqc_reset then ['MQC Reset', :warning]
    when :mqc_passed then ['MQC performed, passed', :ok]
    when :mqc_issues then ['MQC performed, issues', :warning]
    when :mqc_state_change then ['MQC State Change', :warning]
    when :rs_domino_unid_change then ['RS Domino UNID Change', :ok]
    when :rs_assignment_change then ['RS Assignment Change', :warning]
    when :rs_tqc_performed then ['RS TQC performed', :ok]
    when :mqc_performed then ['MQC performed', :ok]
    end
  end

  def to_s
    "#{visit_type}(#{visit_number})"
  end

  protected

  def reset_mqc
    self.mqc_user_id = nil
    self.mqc_date = nil
    self.mqc_state = :pending
    self.mqc_results = {}
    self.mqc_comment = nil
    self.mqc_version = nil

    save
  end

  def mqc_to_domino
    result = {}

    result['QCdate'] = { 'data' => (mqc_date.nil? ? '01-01-0001' : mqc_date.strftime('%d-%m-%Y')), 'type' => 'datetime' }
    result['QCperson'] = (mqc_user.nil? ? nil : mqc_user.name)

    result['QCresult'] =
      case mqc_state_sym
      when :pending then 'Pending'
      when :issues then 'Performed, issues present'
      when :passed then 'Performed, no issues present'
      end

    result['QCcomment'] = mqc_comment

    criteria_names = []
    criteria_values = []
    results = mqc_spec_with_results_at_version(mqc_version)
    if results.nil?
      result['QCCriteriaNames'] = nil
      result['QCValues'] = nil
    else
      results.each do |criterion|
        criteria_names << criterion['label']
        criteria_values << (criterion['answer'] == true ? 'Pass' : 'Fail')
      end

      result['QCCriteriaNames'] = criteria_names.join("\n")
      result['QCValues'] = criteria_values.join("\n")
    end

    result
  end

  def ensure_study_is_unchanged
    if patient_id_changed? && !patient_id_was.nil?
      old_patient = Patient.find(patient_id_was)

      if old_patient.study != patient.study
        errors[:patient] << 'A visit cannot be reassigned to a patient in a different study.'
        return false
      end
    end

    true
  end

  def update_required_series_preset
    return unless saved_change_to_visit_type?

    if visit_type_before_last_save.blank? && visit_type.present?
      add_new_required_series(required_series_spec.keys)
    elsif visit_type_before_last_save.present? && visit_type.present?
      clean_changed_required_series
    elsif visit_type_before_last_save.present? && visit_type.blank?
      remove_required_series
    end
  end

  def clean_changed_required_series
    old_spec = study.required_series_spec(visit_type_before_last_save)
    new_spec = study.required_series_spec(visit_type)

    remove_orphaned_required_series(old_spec.keys - new_spec.keys)
    add_new_required_series(new_spec.keys - old_spec.keys)

    invalidate_tqc_for_changed_spec(old_spec, new_spec)
  end

  def add_new_required_series(new)
    new.each do |name|
      RequiredSeries.create(visit: self, name: name)
    end
  end

  def remove_orphaned_required_series(orphaned)
    RequiredSeries.where(visit: self, name: orphaned).destroy_all
  end

  def remove_required_series
    RequiredSeries.where(visit: self).destroy_all
  end

  def invalidate_tqc_for_changed_spec(old_spec, new_spec)
    (old_spec.keys & new_spec.keys).each do |name|
      next if old_spec[name]['tqc'] == new_spec[name]['tqc']
      RequiredSeries.where(visit: self, name: name).each(&:reset_tqc!)
    end
  end
end
