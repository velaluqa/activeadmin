# ## Schema Information
#
# Table name: `image_series`
#
# ### Columns
#
# Name                      | Type               | Attributes
# ------------------------- | ------------------ | ---------------------------
# **`comment`**             | `string`           |
# **`created_at`**          | `datetime`         |
# **`domino_unid`**         | `string`           |
# **`id`**                  | `integer`          | `not null, primary key`
# **`imaging_date`**        | `date`             |
# **`name`**                | `string`           |
# **`patient_id`**          | `integer`          |
# **`properties`**          | `jsonb`            | `not null`
# **`properties_version`**  | `string`           |
# **`series_number`**       | `integer`          |
# **`state`**               | `integer`          | `default(0)`
# **`updated_at`**          | `datetime`         |
# **`visit_id`**            | `integer`          |
#
# ### Indexes
#
# * `index_image_series_on_patient_id`:
#     * **`patient_id`**
# * `index_image_series_on_patient_id_and_series_number`:
#     * **`patient_id`**
#     * **`series_number`**
# * `index_image_series_on_series_number`:
#     * **`series_number`**
# * `index_image_series_on_visit_id`:
#     * **`visit_id`**
#
class ImageSeries < ActiveRecord::Base
  include DominoDocument

  has_paper_trail(
    class_name: 'Version',
    meta: {
      study_id: ->(series) { series.study.andand.id }
    }
  )
  acts_as_taggable

  attr_accessible(
    :name,
    :visit_id,
    :patient_id,
    :imaging_date,
    :domino_unid,
    :series_number,
    :state,
    :comment,
    :visit,
    :patient,
    :properties,
    :properties_version
  )

  belongs_to :visit
  belongs_to :patient
  has_many :images, dependent: :destroy

  # validates_uniqueness_of :series_number, :scope => :patient_id
  validates_presence_of :name, :patient_id, :imaging_date

  scope :not_assigned, -> { where(visit_id: nil) }

  scope :by_study_ids, ->(*ids) {
    joins(patient: :center)
      .where(centers: { study_id: Array[ids].flatten })
  }

  scope :searchable, -> { join_study.select(<<SELECT.strip_heredoc) }
    centers.study_id AS study_id,
    studies.name AS study_name,
    image_series.name || ' (' || image_series.series_number::text || ')' AS text,
    image_series.id AS result_id,
    'ImageSeries'::varchar AS result_type
SELECT

  scope :join_study, -> { joins(patient: { center: :study }) }

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

  before_save :ensure_study_is_unchanged
  before_save :ensure_visit_is_for_patient
  before_save :update_state

  # before_validation :assign_series_number

  STATE_SYMS = %i[importing imported visit_assigned required_series_assigned not_required].freeze

  def state_index
    read_attribute(:state)
  end

  def self.state_sym_to_int(sym)
    ImageSeries::STATE_SYMS.index(sym)
  end

  def self.int_to_state_sym(sym)
    ImageSeries::STATE_SYMS[sym]
  end

  def state
    return -1 if read_attribute(:state).nil?
    read_attribute(:state)
  end

  def state_sym
    return -1 if read_attribute(:state).nil?
    STATE_SYMS[read_attribute(:state)]
  end

  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = if sym.is_a? Integer
              sym
            else
              ImageSeries::STATE_SYMS.index(sym)
            end

    if index.nil?
      throw 'Unsupported state'
      return
    end

    write_attribute(:state, index)
  end

  def study
    if patient.nil?
      nil
    else
      patient.study
    end
  end

  def image_storage_path
    if visit
      "#{visit.image_storage_path}/#{id}"
    else
      "#{patient.image_storage_path}/__unassigned/#{id}"
    end
  end

  def absolute_image_storage_path
    Rails.application.config.image_storage_root + '/' + image_storage_path
  end

  def wado_query
    { id: id, name: name, images: images.order('id ASC') }
  end

  def sample_image
    return nil if images.empty?
    images[(images.count - 1) / 2]
  end

  def domino_document_form
    'SeriesInventory'
  end

  def domino_document_query
    {
      'docCode' => 10_043,
      'ericaID' => id
    }
  end

  def domino_document_properties(_action = :update)
    properties = {
      'ericaID' => id,
      'CenterNo' => patient.center.code,
      'PatNo' => patient.domino_patient_no,
      'VisitNo' => (visit.nil? ? nil : visit.visit_number),
      'DateImaging' => { 'data' => imaging_date.strftime('%d-%m-%Y'), 'type' => 'datetime' }, # this is utterly ridiculous: sending the date in the corrent format (%Y-%m-%d) leads switched month/day for days where this can work (1-12). sending a completely broken format leads to correct parses... *doublefacepalm*
      'SeriesDescription' => name,
      'AssignedTo' => (assigned_required_series.nil? ? nil : assigned_required_series.join("\n"))
    }

    properties.merge!(dicom_metadata_to_domino)
    properties.merge!(properties_to_domino)

    properties
  end

  def domino_sync
    ensure_domino_document_exists

    unless visit.nil?
      # the reload call is here to work around a race condition in the domino sync
      # when an image series is re/unassigned on a visit that had mQC completed, the image series sync is started first
      # it then starts its visit sync, possibly after the visit was modified and had its mQC results reset
      # this visit instance would then contain the old values, including the mQC details
      # therefor, we reload it here before we sync it, to make sure we have the most up-to-date values
      visit.reload
      visit.domino_sync

      assigned_required_series_names = assigned_required_series || []
      assigned_required_series_names.each do |as_name|
        RequiredSeries.new(visit, as_name).domino_sync
      end
    end
  end

  def assigned_required_series
    visit.andand.assigned_image_series_index.andand[id.to_s].andand.deep_dup || []
  end

  def change_required_series_assignment(new_assignment)
    return if visit.nil?
    changes = {}

    current_assignment = assigned_required_series

    pp current_assignment
    pp new_assignment

    (current_assignment - new_assignment).each do |unassigned_required_series|
      changes[unassigned_required_series] = nil
    end
    (new_assignment - current_assignment).each do |assigned_required_series|
      changes[assigned_required_series] = id.to_s
    end

    visit.change_required_series_assignment(changes)
  end

  def dicom_metadata_to_domino
    study_config = (study.nil? ? nil : study.locked_configuration)
    result = {}

    unless images.empty?
      image = sample_image

      unless image.nil?
        dicom_meta_header, dicom_metadata = image.dicom_metadata

        if study_config && study.semantically_valid?
          dicom_tag_names = []
          dicom_values = []
          study_config['domino_integration']['dicom_tags'].each_with_index do |tag, _i|
            dicom_values << (dicom_metadata[tag['tag']].nil? ? 'N/A' : dicom_metadata[tag['tag']][:value]).to_s
            dicom_tag_names << tag['label'].to_s
          end

          result['DICOMTagNames'] = dicom_tag_names.join("\n")
          result['DICOMValues'] = dicom_values.join("\n")
        end
      end
    end

    result
  end

  alias_method :original_to_json, :to_json
  def to_json
    attributes.merge(
      state: state_sym
    ).to_json
  end

  # fake attributes for the somewhat laborious implementation of visit assignment changes
  def force_update
    @force_update
  end

  def force_update=(val)
    @force_update = val
  end

  protected

  def properties_to_domino
    properties_version = if study.nil?
                           nil
                         elsif properties_version.blank?
                           study.locked_version
                         else
                           properties_version
                         end
    study_config = study.andand.configuration_at_version(properties_version)
    result = {}

    if study_config && study.semantically_valid_at_version?(properties_version) && properties
      properties_spec = study_config['image_series_properties']
      property_names = []
      property_values = []

      processed_properties = []

      unless properties_spec.nil?
        properties_spec.each do |property|
          property_names << property['label']

          raw_value = properties[property['id']]
          value = case property['type']
                  when 'string'
                    raw_value
                  when 'bool'
                    if raw_value.nil?
                      'Not set'
                    else
                      raw_value ? 'Yes' : 'No'
                    end
                  when 'select'
                    property['values'][raw_value].nil? ? raw_value : property['values'][raw_value]
                  else
                    raw_value
                  end
          value = 'Not set' if value.blank?

          property_values << value
          processed_properties << property['id']
        end
      end

      properties.each do |id, value|
        next if processed_properties.include?(id)
        property_names << id.to_s
        property_values << (value.blank? ? 'Not set' : value.to_s)
      end

      result = { 'PropertyNames' => property_names.join("\n"), 'PropertyValues' => property_values.join("\n") }
    end

    result
  end

  def ensure_study_is_unchanged
    if patient_id_changed? && !patient_id_was.nil?
      old_patient = Patient.find(patient_id_was)

      if old_patient.study != patient.study
        errors[:patient] << 'An image series cannot be reassigned to a patient in a different study.'
        return false
      end
    end

    true
  end

  def ensure_visit_is_for_patient
    if visit && visit.patient != patient
      errors[:visit] << 'The visits patient is different from this image series\' patient'
      false
    else
      true
    end
  end

  def assign_series_number
    if new_record? && series_number.nil? && patient
      self.series_number = patient.next_series_number
    end
  end

  def update_state
    if visit_id_changed?
      old_visit_id = changes[:visit_id][0]
      new_visit_id = changes[:visit_id][1]

      if !old_visit_id.nil? && new_visit_id.nil?
        self.state = :imported
      elsif old_visit_id.nil? && !new_visit_id.nil? && state_sym == :imported
        self.state = :visit_assigned
      end
    end
  end

  # reassigning an image series to a different visit:
  # * check if new visit has same visit type as current visit
  # * if yes:
  #   * check if there is already an assignment for any of the required series' this image series is currently assigned to in the new visit
  #   * if yes:
  #     * ask user if he wants to go ahead
  #     * if yes: continue
  #     * if no: cancel move
  #   * if no:
  #     * for all required series to which we are assigned:
  #       * unassign this image series from required series in current visit: current_visit.change_required_series_assignment({currently_assigned_required_series_name => nil})
  #       * assign this image series to required series in new visit: new_visit.change_required_series_assignment({currently_assigned_required_series_name => self.id})
  # * if no:
  #   * for all required series to which we are assigned:
  #     * unassign this image series from required series in current visit: current_visit.change_required_series_assignment({currently_assigned_required_series_name => nil})

  def self.classify_audit_trail_event(c)
    # ignore Domino UNID changes that happened along with a property change
    c.delete('domino_unid')

    if c.keys == ['name']
      :name_change
    elsif c.keys == ['comment']
      :comment_change
    elsif c.keys == ['center_id']
      :center_change
    elsif c.keys == ['imaging_date']
      :imaging_date_change
    elsif c.keys == ['series_number']
      :series_number_change
    elsif c.keys == ['visit_id']
      :visit_assignment_change
    elsif c.keys == ['patient_id']
      :patient_change
    elsif c.include?('state')
      case [int_to_state_sym(c['state'][0].to_i), c['state'][1]]
      when %i[imported visit_assigned], %i[not_required visit_assigned] then :visit_assigned
      when %i[visit_assigned required_series_assigned], %i[not_required required_series_assigned] then :required_series_assigned
      when %i[required_series_assigned visit_assigned] then :required_series_unassigned
      when %i[visit_assigned imported], %i[required_series_assigned imported] then :visit_unassigned
      when %i[imported not_required], %i[visit_assigned not_required], %i[required_series_assigned not_required] then :marked_not_required
      when %i[not_required imported] then :unmarked_not_required
      end
    elsif (c.keys - %w[properties properties_version]).empty?
      :properties_change
    end
  end

  def self.audit_trail_event_title_and_severity(event_symbol)
    case event_symbol
    when :name_change then ['Name Change', :warning]
    when :comment_change then ['Comment Change', :warning]
    when :center_change then ['Center Change', :warning]
    when :visit_assigned then ['Assigned to visit', :ok]
    when :visit_unassigned then ['Visit assignment removed', :warning]
    when :required_series_assigned then ['Assigned as required series', :ok]
    when :required_series_unassigned then ['Required series assignment removed', :warning]
    when :visit_assignment_change then ['Visit assignment changed', :ok]
    when :marked_not_required then ['Marked as not required', :warning]
    when :unmarked_not_required then ['Not required flag revoked', :warning]
    when :imaging_date_change then ['Imaging Date Change', :ok]
    when :series_number_change then ['Series Number Change', :ok]
    when :patient_change then ['Patient Change', :warning]
    when :properties_change then ['Properties Change', :ok]
    end
  end
end
