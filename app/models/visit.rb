require 'git_config_repository'

# ## Schema Information
#
# Table name: `visits`
#
# ### Columns
#
# Name                               | Type               | Attributes
# ---------------------------------- | ------------------ | ---------------------------
# **`assigned_image_series_index`**  | `jsonb`            | `not null`
# **`created_at`**                   | `datetime`         |
# **`description`**                  | `string`           |
# **`domino_unid`**                  | `string`           |
# **`id`**                           | `integer`          | `not null, primary key`
# **`mqc_comment`**                  | `string`           |
# **`mqc_date`**                     | `datetime`         |
# **`mqc_results`**                  | `jsonb`            | `not null`
# **`mqc_state`**                    | `integer`          | `default(0)`
# **`mqc_user_id`**                  | `integer`          |
# **`mqc_version`**                  | `string`           |
# **`patient_id`**                   | `integer`          |
# **`repeatable_count`**             | `integer`          | `default(0), not null`
# **`required_series`**              | `jsonb`            | `not null`
# **`state`**                        | `integer`          | `default(0)`
# **`updated_at`**                   | `datetime`         |
# **`visit_number`**                 | `integer`          |
# **`visit_type`**                   | `string`           |
#
# ### Indexes
#
# * `index_visits_on_assigned_image_series_index`:
#     * **`assigned_image_series_index`**
# * `index_visits_on_mqc_results`:
#     * **`mqc_results`**
# * `index_visits_on_mqc_user_id`:
#     * **`mqc_user_id`**
# * `index_visits_on_patient_id`:
#     * **`patient_id`**
# * `index_visits_on_required_series`:
#     * **`required_series`**
# * `index_visits_on_visit_number`:
#     * **`visit_number`**
#
class Visit < ActiveRecord::Base
  include NotificationObservable
  include DominoDocument

  has_paper_trail class_name: 'Version'
  acts_as_taggable

  attr_accessible :patient_id, :visit_number, :description, :visit_type, :state, :domino_unid
  attr_accessible :patient
  attr_accessible :mqc_date, :mqc_user_id, :mqc_state
  attr_accessible :assigned_image_series_index, :required_series
  attr_accessible :mqc_user, :mqc_results
  
  belongs_to :patient
  has_many :image_series, after_add: :schedule_domino_sync, after_remove: :schedule_domino_sync
  belongs_to :mqc_user, :class_name => 'User'

  scope :by_study_ids, lambda { |*ids|
    joins(patient: { center: :study })
      .where(studies: { id: Array[ids].flatten })
  }

  scope :with_state, lambda { |state|
    index =
      case state
      when Fixnum then state
      else Visit::STATE_SYMS.index(state.to_sym)
      end
    where(state: index)
  }

  scope :searchable, -> { joins(patient: :center).select(<<SELECT) }
centers.study_id AS study_id,
centers.code ||
patients.subject_id ||
'#' ||
visits.visit_number ||
CASE WHEN visits.repeatable_count > 0 THEN ('.' || visits.repeatable_count) ELSE '' END 
AS text,
visits.id AS result_id,
'Visit' AS result_type
SELECT

  validates_uniqueness_of :visit_number, :scope => :patient_id
  validates_presence_of :visit_number, :patient_id

  before_destroy do
    self.image_series.each do |is|
      is.visit = nil
      is.save
    end
  end

  before_save :ensure_study_is_unchanged

  include ImageStorageCallbacks
  include ScopablePermissions

  def self.with_permissions
    joins(patient: { center: :study }).joins(<<JOIN)
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
  scope :filter, lambda { |query|
    return unless query

    words = query.split(' ')
    conditions = words.map { 'CONCAT(visit_number, visit_type) LIKE ?' }.join(' AND ')
    terms = words.map { |word| "%#{word}%" }

    where(conditions, *terms)
  }

  scope :join_study, -> { joins(patient: { center: :study }) }

  scope :join_required_series, lambda {
    joins(<<JOIN_QUERY)
JOIN json_each(visits.required_series::json) visits_required_series_hash ON true
JOIN json_to_record(visits_required_series_hash.value) as visits_required_series(tqc_state int) ON true
JOIN_QUERY
  }

  scope :of_study, lambda { |study|
    study_id = study
    study_id = study.id if study.is_a?(ActiveRecord::Base)
    joins(patient: :center).where(centers: { study_id: study_id })
  }

  def name
    if(patient.nil?)
      '#'+visit_number.to_s
    else
      patient.name+'#'+visit_number.to_s
    end
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
    self.image_series.map {|is| is.imaging_date}.reject {|date| date.nil? }.min
  end

  def study
    if self.patient.nil?
      nil
    else
      self.patient.study
    end
  end

  STATE_SYMS = [:incomplete_na, :complete_tqc_passed, :incomplete_queried, :complete_tqc_pending, :complete_tqc_issues]
  MQC_STATE_SYMS = [:pending, :issues, :passed]

  def self.state_sym_to_int(sym)
    return Visit::STATE_SYMS.index(sym)
  end
  def self.int_to_state_sym(sym)
    return Visit::STATE_SYMS[sym]
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
    if sym.is_a? Fixnum
      index = sym
    else
      index = Visit::STATE_SYMS.index(sym)
    end

    if index.nil?
      throw "Unsupported state"
      return
    end

    write_attribute(:state, index)
  end
  def self.mqc_state_sym_to_int(sym)
    return Visit::MQC_STATE_SYMS.index(sym)
  end
  def self.int_to_mqc_state_sym(sym)
    return Visit::MQC_STATE_SYMS[sym]
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
    if sym.is_a? Fixnum
      index = sym
    else
      index = Visit::MQC_STATE_SYMS.index(sym)
    end

    if index.nil?
      throw "Unsupported mQC state"
      return
    end

    write_attribute(:mqc_state, index)
  end


  def current_required_series_specs
    return nil if(self.visit_type.nil? or self.study.nil? or not self.study.semantically_valid?)

    required_series_specs_for_configuration(self.study.current_configuration)
  end
  def locked_required_series_specs
    return nil if(self.visit_type.nil? or self.study.nil? or not self.study.locked_semantically_valid?)

    required_series_specs_for_configuration(self.study.locked_configuration)
  end
  def required_series_specs_at_version(version)
    return nil if(self.visit_type.nil? or self.study.nil? or not self.study.semantically_valid_at_version?(version))    

    required_series_specs_for_configuration(self.study.configuration_at_version(version))
  end
  def required_series_specs_for_configuration(study_config)
    return nil if self.visit_type.nil?

    return nil if(study_config['visit_types'][self.visit_type].nil? or study_config['visit_types'][self.visit_type]['required_series'].nil?)
    required_series = study_config['visit_types'][self.visit_type]['required_series']

    return required_series
  end

  def required_series_names
    required_series_specs = self.locked_required_series_specs
    return nil if required_series_specs.nil?
    return required_series_specs.keys
  end
  def required_series_objects
    required_series_names = self.required_series_names
    return [] if required_series_names.nil?

    objects = required_series_names.map do |required_series_name|
      RequiredSeries.new(self, required_series_name)
    end

    return objects
  end
  def assigned_required_series(required_series_name)
    required_series = self.required_series(required_series_name)
    return nil unless required_series.andand['image_series_id']

    ImageSeries.find(required_series['image_series_id'])
  end
  def assigned_required_series_id_map
    id_map = {}
    required_series.each do |required_series_name, required_series|
      id_map[required_series_name] = required_series['image_series_id']
    end

    return id_map
  end
  def assigned_required_series_map
    map = assigned_required_series_id_map
    object_map = {}
    map.each do |series_name, series_id|
      object_map[series_name] = ImageSeries.find(series_id) unless series_id.nil?
    end

    return object_map
  end

  def remove_orphaned_required_series
    current_required_series_names = required_series_names
    return if current_required_series_names.nil?

    saved_required_series_names = required_series.andand.keys || []

    orphaned_required_series_names = (saved_required_series_names - current_required_series_names)
    unless orphaned_required_series_names.empty?
      changed_assignments = {}

      orphaned_required_series_names.each do |orphaned_required_series_name|
        RequiredSeries.new(self, orphaned_required_series_name).schedule_domino_document_trashing

        deleted_series = required_series.delete(orphaned_required_series_name)
        if deleted_series.andand['image_series_id']
          changed_assignments[orphaned_required_series_name] = nil
        end
      end

      change_required_series_assignment(changed_assignments, save: false)

      save

      Rails.logger.info "Removed #{orphaned_required_series_names.size} orphaned required series from visit #{self.inspect}: #{orphaned_required_series_names.inspect}"
    end
  end

  def image_storage_path
    "#{patient.image_storage_path}/#{id}"
  end
  def required_series_image_storage_path(required_series_name)
    "#{image_storage_path}/#{required_series_name}"
  end

  def wado_query
    {:id => self.id, :name => "Visit No. #{visit_number}", :image_series => 
      self.image_series.map {|i_s| i_s.wado_query}
    }
  end
  def required_series_wado_query
    {:id => self.id, :name => "Visit No. #{visit_number}", :image_series => 
      self.required_series_objects.reject {|rs| not rs.assigned?}.map {|rs| rs.wado_query}.reject {|query| query.blank?}
    }
  end

  def domino_document_form
    'ImagingVisit_mqc'
  end
  def domino_document_query
    {
      'docCode' => 10045,
      'ericaID' => self.id,
    }
  end
  def domino_document_properties(action = :update)
    properties = {
      'ericaID' => id,
      'CenterNo' => patient.center.code,
      'PatNo' => patient.domino_patient_no,
      'VisitNo' => self.visit_number,
      'visitDescription' => self.description,
    }

    visit_date = self.visit_date
    unless(visit_date.nil?)
      properties.merge!({
                          'DateImaging' => {'data' => visit_date.strftime('%d-%m-%Y'), 'type' => 'datetime'},
                        })
    end

    properties.merge!(mqc_to_domino)

    properties['Status'] = case self.state_sym
                                when :incomplete_na then 'Incomplete, not available'
                                when :complete_tqc_passed then 'Complete, tQC of all series passed'
                                when :incomplete_queried then 'Incomplete, queried'
                                when :complete_tqc_pending then 'Complete, tQC not finished'
                                when :complete_tqc_issues then 'Complete, tQC finished, not all series passed'
                                end

    properties
  end
  def schedule_domino_sync
    DominoSyncWorker.perform_async(self.class.to_s, self.id)
    self.schedule_required_series_domino_sync
  end
  def domino_sync
    self.ensure_domino_document_exists
  end
  def schedule_required_series_domino_sync
    self.required_series_objects.each do |required_series|
      required_series.schedule_domino_sync
    end
  end

  def rename_required_series(old_name, new_name)
    return unless required_series

    # Rename in `required_series`
    required_series_data = required_series.delete(old_name)
    required_series[new_name] = required_series_data if required_series_data

    # Rename in `assigned_image_series_index`
    return if assigned_image_series_index.blank?
    assigned_image_series_index.each do |series_id, assignment|
      if assignment.include?(old_name)
        assignment.delete(old_name)
        assignment << new_name
      end
    end
    
    image_storage_root = Rails.application.config.image_storage_root
    image_storage_root += '/' unless(image_storage_root.end_with?('/')
                                    )
    if File.exists?(image_storage_root + self.required_series_image_storage_path(old_name))
      FileUtils.mv(image_storage_root + self.required_series_image_storage_path(old_name), image_storage_root + self.required_series_image_storage_path(new_name))
    end

    save

    RequiredSeries.new(self, new_name).schedule_domino_sync
  end

  def change_required_series_assignment(changed_assignments, options = { save: true })
    assignment_index = assigned_image_series_index

    old_assigned_image_series = assignment_index.reject {|series_id, assignment| assignment.nil? or assignment.empty?}.keys

    image_storage_root = Rails.application.config.image_storage_root
    image_storage_root += '/' unless(image_storage_root.end_with?('/'))

    domino_sync_series_ids = []
    
    changed_assignments.each do |required_series_name, series_id|
      series_id = (series_id.blank? ? nil : series_id)
      old_series_id = nil
      required_series[required_series_name] = {} unless required_series[required_series_name]

      if required_series[required_series_name]['image_series_id']
        old_series_id = required_series[required_series_name]['image_series_id'].to_s

        if !old_series_id.blank? && assignment_index[old_series_id]
          assignment_index[old_series_id].delete(required_series_name)
        end
      end

      required_series[required_series_name]['image_series_id'] = series_id

      if series_id
        assignment_index[series_id] ||= []
        unless assignment_index[series_id].include?(required_series_name)
          assignment_index[series_id] << required_series_name
        end
      end

      if(required_series[required_series_name]['image_series_id'].nil?)
        FileUtils.rm(image_storage_root + self.required_series_image_storage_path(required_series_name), :force => true)
      else
        FileUtils.rm(image_storage_root + self.required_series_image_storage_path(required_series_name), :force => true)
        FileUtils.ln_sf(series_id, image_storage_root + self.required_series_image_storage_path(required_series_name))
      end

      if(old_series_id != series_id)
        required_series[required_series_name]['tqc_state'] = RequiredSeries.tqc_state_sym_to_int(:pending)
        required_series[required_series_name].delete('tqc_user_id')
        required_series[required_series_name].delete('tqc_date')
        required_series[required_series_name].delete('tqc_version')
        required_series[required_series_name].delete('tqc_results')
        required_series[required_series_name].delete('tqc_comment')
      end

      domino_sync_series_ids << old_series_id unless old_series_id.blank?
      domino_sync_series_ids << series_id unless series_id.blank?
    end
    
    new_assigned_image_series = assignment_index.reject {|series_id, assignment| assignment.nil? or assignment.empty?}.keys
    (old_assigned_image_series - new_assigned_image_series).uniq.each do |unassigned_series_id|
      unassigned_series = ImageSeries.where(:id => unassigned_series_id).first
      if(unassigned_series and unassigned_series.state == :required_series_assigned)
        unassigned_series.state = (unassigned_series.visit.nil? ? :imported : :visit_assigned)
        unassigned_series.save
      end
    end
    (new_assigned_image_series - old_assigned_image_series).uniq.each do |assigned_series_id|
      assigned_series = ImageSeries.where(:id => assigned_series_id).first
      if(assigned_series and assigned_series.state == :visit_assigned || assigned_series.state == :not_required)
        assigned_series.state = :required_series_assigned
        assigned_series.save
      end
    end

    reconstruct_assignment_index

    save if options[:save]

    schedule_required_series_domino_sync

    domino_sync_series_ids.uniq.each do |series_id|
      image_series = ImageSeries.where(:id => series_id).first
      image_series.schedule_domino_sync unless image_series.nil?
    end
  end

  def reconstruct_assignment_index
    new_index = {}
    
    required_series.each do |rs_name, data|
      next if data['image_series_id'].blank?

      new_index[data['image_series_id']] ||= []
      new_index[data['image_series_id']] << rs_name
    end

    self.assigned_image_series_index = new_index
  end
  
  def reset_tqc_result(required_series_name)
    return unless required_series.andand[required_series_name]

    required_series[required_series_name]['tqc_state'] = :pending
    required_series[required_series_name].delete('tqc_user_id')
    required_series[required_series_name].delete('tqc_date')
    required_series[required_series_name].delete('tqc_version')
    required_series[required_series_name].delete('tqc_results')
    required_series[required_series_name].delete('tqc_comment')

    save

    RequiredSeries.new(self, required_series_name).schedule_domino_sync
  end
  def set_tqc_result(required_series_name, result, tqc_user, tqc_comment, tqc_date = nil, tqc_version = nil)
    required_series_specs = self.locked_required_series_specs
    return 'No valid study configuration exists.' if required_series_specs.nil?

    tqc_spec = (required_series_specs[required_series_name].nil? ? nil : required_series_specs[required_series_name]['tqc'])
    return 'No tQC config for this required series exists.' if tqc_spec.nil?

    all_passed = true
    tqc_spec.each do |spec|
      all_passed &&= (not result.nil? and result[spec['id']] == true)
    end

    required_series = required_series[required_series_name]
    return 'No assignment for this required series exists.' if required_series.nil?

    required_series['tqc_state'] = RequiredSeries.tqc_state_sym_to_int((all_passed ? :passed : :issues))
    required_series['tqc_user_id'] = (tqc_user.is_a?(User) ? tqc_user.id : tqc_user)
    required_series['tqc_date'] = (tqc_date.nil? ? Time.now : tqc_date)
    required_series['tqc_version'] = (tqc_version.nil? ? self.study.locked_version : tqc_version)
    required_series['tqc_results'] = result
    required_series['tqc_comment'] = tqc_comment

    required_series[required_series_name] = required_series
    save

    RequiredSeries.new(self, required_series_name).schedule_domino_sync
    return true
  end
  def set_mqc_result(result, mqc_user, mqc_comment, mqc_date = nil, mqc_version = nil)
    mqc_spec = self.locked_mqc_spec
    return 'No valid study configuration exists or it doesn\'t contain an mQC config for this visits visit type.' if mqc_spec.nil?

    all_passed = true
    mqc_spec.each do |spec|
      all_passed &&= (not result.nil? and result[spec['id']] == true)
    end

    self.mqc_state_sym = all_passed ? :passed : :issues
    self.mqc_user_id = mqc_user.is_a?(User) ? mqc_user.id : mqc_user
    self.mqc_date = mqc_date || Time.now
    self.mqc_results = result
    self.mqc_comment = mqc_comment
    self.mqc_version = mqc_version || study.andand.locked_version

    self.save

    return true
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
    reutrn mqc_spec_at_version(self.mqc_version || self.study.locked_version)
  end

  def locked_mqc_spec
    return mqc_spec_at_version(self.study.locked_version)
  end

  def mqc_spec_at_version(version)
    config = study.configuration_at_version(version)
    return nil if config.nil? or config['visit_types'].nil? or config['visit_types'][self.visit_type].nil?
    
    return config['visit_types'][self.visit_type]['mqc']
  end

  def locked_mqc_spec_with_results
    return nil if locked_mqc_spec.nil? or mqc_results.blank?

    locked_mqc_spec.each do |question|
      question['answer'] = mqc_results[question['id']]
    end

    locked_mqc_spec
  end
  def locked_mqc_spec_with_results
    return mqc_spec_with_results_at_version(self.study.locked_version)
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

    if(c.keys == ['visit_number'])
      :visit_number_change
    elsif(c.keys == ['patient_id'])
      :patient_change
    elsif(c.keys == ['description'])
      :description_change
    elsif(c.keys == ['visit_type'])
      :visit_type_change
    elsif(c.keys == ['state'])
      # handle obsolete mqc states in state
      case c['state'][1]
      when :mqc_passed
        :mqc_passed
      when :mqc_issues
        :mqc_issues
      else
        :state_change
      end
    elsif(c.include?('mqc_state') and (c.keys - ['mqc_state', 'mqc_date', 'mqc_user_id']).empty?)
      case [int_to_mqc_state_sym(c['mqc_state'][0].to_i), c['mqc_state'][1]]
      when [:passed, :pending], [:issues, :pending] then :mqc_reset
      when [:pending, :passed] then :mqc_passed
      when [:pending, :issues] then :mqc_issues
      when [:issues, :passed] then :mqc_passed
      when [:passed, :issues] then :mqc_issues
      else :mqc_state_change
      end
    elsif(c.include?('mqc_user_id') and c.include?('mqc_date') and c.keys.length == 2 and
          c['mqc_user_id'][1].blank? and c['mqc_date'][1].blank?)
      :mqc_reset
    elsif(c.include?('state') and c.include?('mqc_date') and (2..3).include?(c.keys.length))
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

      if(c.keys == ['required_series'])
        if(diffs.all? {|rs, diff| (diff.keys - ['domino_unid']).empty?})
          :rs_domino_unid_change
        elsif(diffs.all? {|rs, diff| (diff.keys - ['domino_unid', 'tqc_state', 'tqc_results', 'tqc_date', 'tqc_version', 'tqc_user_id', 'tqc_comment']).empty?})
          :rs_tqc_performed
        end
      elsif((c.keys - ['required_series', 'assigned_image_series_index']).empty?)
        if(diffs.all? {|rs, diff|
             (diff.keys - ['domino_unid', 'image_series_id', 'tqc_state', 'tqc_results', 'tqc_date', 'tqc_version', 'tqc_user_id', 'tqc_comment']).empty? and
               ((diff.keys & ['tqc_results', 'tqc_date', 'tqc_version', 'tqc_user_id', 'tqc_comment']).empty? or
                (
                  (diff['tqc_state'].nil? or diff['tqc_state'] == 0) and
                  c['required_series'][1][rs]['tqc_results'].nil? and
                  c['required_series'][1][rs]['tqc_date'].nil? and
                  c['required_series'][1][rs]['tqc_version'].nil? and
                  c['required_series'][1][rs]['tqc_user_id'].nil? and
                  c['required_series'][1][rs]['tqc_comment'].nil?
                )
               )
           })
          :rs_assignment_change
        end
      end
    elsif (c.keys - %w{mqc_version mqc_results mqc_comment}).empty?
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

    self.save
  end
  def mqc_to_domino
    result = {}

    result['QCdate'] = {'data' => (self.mqc_date.nil? ? '01-01-0001' : self.mqc_date.strftime('%d-%m-%Y')), 'type' => 'datetime'}
    result['QCperson'] = (self.mqc_user.nil? ? nil : self.mqc_user.name)

    result['QCresult'] = case mqc_state_sym
                         when :pending then 'Pending'
                         when :issues then 'Performed, issues present'
                         when :passed then 'Performed, no issues present'
                         end

    result['QCcomment'] = mqc_comment

    criteria_names = []
    criteria_values = []
    results = self.mqc_spec_with_results_at_version(mqc_version)
    if(results.nil?)
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

    return result
  end

  def ensure_study_is_unchanged
    if(self.patient_id_changed? and not self.patient_id_was.nil?)
      old_patient = Patient.find(self.patient_id_was)

      if(old_patient.study != self.patient.study)
        self.errors[:patient] << 'A visit cannot be reassigned to a patient in a different study.'
        return false
      end
    end

    return true
  end
end
