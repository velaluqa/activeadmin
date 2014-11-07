require 'domino_document_mixin'
require 'git_config_repository'

class Visit < ActiveRecord::Base
  include DominoDocument

  has_paper_trail

  attr_accessible :patient_id, :visit_number, :description, :visit_type, :state, :domino_unid
  attr_accessible :patient
  attr_accessible :mqc_date, :mqc_user_id, :mqc_state
  attr_accessible :mqc_user
  
  belongs_to :patient
  has_many :image_series, after_add: :schedule_domino_sync, after_remove: :schedule_domino_sync
  has_one :visit_data
  belongs_to :mqc_user, :class_name => 'User'

  validates_uniqueness_of :visit_number, :scope => :patient_id
  validates_presence_of :visit_number, :patient_id

  before_destroy do
    self.image_series.each do |is|
      is.visit = nil
      is.save
    end
  end

  before_save :ensure_study_is_unchanged

  after_create :ensure_visit_data_exists
  before_destroy :destroy_visit_data

  def name
    if(patient.nil?)
      '#'+visit_number.to_s
    else
      patient.name+'#'+visit_number.to_s
    end
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
    return Visit::STATE_SYMS[read_attribute(:state)]
  end
  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = Visit::STATE_SYMS.index(sym)

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
    return -1 if read_attribute(:state).nil?
    return Visit::MQC_STATE_SYMS[read_attribute(:mqc_state)]
  end
  def mqc_state=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = Visit::MQC_STATE_SYMS.index(sym)

    if index.nil?
      throw "Unsupported mQC state"
      return
    end

    write_attribute(:mqc_state, index)
  end

  def visit_data
    VisitData.where(:visit_id => read_attribute(:id)).first    
  end
  def ensure_visit_data_exists
    VisitData.create(:visit_id => self.id) if self.visit_data.nil?
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
  def required_series
    self.ensure_visit_data_exists
    return self.visit_data.required_series
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
    self.ensure_visit_data_exists

    required_series = self.required_series(required_series_name)
    return nil if(required_series.nil? or required_series['image_series_id'].nil?)

    return ImageSeries.find(required_series['image_series_id'])
  end
  def assigned_required_series_id_map
    self.ensure_visit_data_exists

    id_map = {}
    self.visit_data.required_series.each do |required_series_name, required_series|
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
    current_required_series_names = self.required_series_names
    return if current_required_series_names.nil?

    visit_data = self.visit_data
    saved_required_series_names = (visit_data.nil? or visit_data.required_series.nil? ? [] : visit_data.required_series.keys)

    pp current_required_series_names
    pp saved_required_series_names
    orphaned_required_series_names = (saved_required_series_names - current_required_series_names)
    pp orphaned_required_series_names
    unless(orphaned_required_series_names.empty?)
      required_series = visit_data.required_series
      changed_assignments = {}

      orphaned_required_series_names.each do |orphaned_required_series_name|
        RequiredSeries.new(self, orphaned_required_series_name).schedule_domino_document_trashing

        deleted_series = required_series.delete(orphaned_required_series_name)
        changed_assignments[orphaned_required_series_name] = nil unless (deleted_series.nil? or deleted_series['image_series_id'].nil?)        
      end

      self.change_required_series_assignment(changed_assignments)
      visit_data.required_series = required_series
      visit_data.save
      
      Rails.logger.info "Removed #{orphaned_required_series_names.size} orphaned required series from visit #{self.inspect}: #{orphaned_required_series_names.inspect}"
    end
  end

  def previous_image_storage_path
    if(self.previous_changes.include?(:patient_id))
      previous_patient = Patient.find(self.previous_changes[:patient_id][0])
      
      previous_patient.image_storage_path + '/' + self.id.to_s
    else
      image_storage_path
    end
  end
  def image_storage_path
    self.patient.image_storage_path + '/' + self.id.to_s
  end
  def required_series_image_storage_path(required_series_name)
    self.image_storage_path + '/' + required_series_name
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

    properties['Status'] = case self.state
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
    visit_data = self.visit_data
    return if visit_data.nil? or visit_data.required_series.nil?

    required_series_data = visit_data.required_series.delete(old_name)
    unless(required_series_data.nil?)
      visit_data.required_series[new_name] = required_series_data
    end

    unless(visit_data.assigned_image_series_index.nil?)
      visit_data.assigned_image_series_index.each do |series_id, assignment|
        if(assignment.include?(old_name))
          assignment.delete(old_name)
          assignment << new_name
        end
      end
    end
    
    image_storage_root = Rails.application.config.image_storage_root
    image_storage_root += '/' unless(image_storage_root.end_with?('/'))
    FileUtils.mv(image_storage_root + self.required_series_image_storage_path(old_name), image_storage_root + self.required_series_image_storage_path(new_name)) if File.exists?(image_storage_root + self.required_series_image_storage_path(old_name))

    visit_data.save
    RequiredSeries.new(self, new_name).schedule_domino_sync
  end

  def change_required_series_assignment(changed_assignments)
    self.ensure_visit_data_exists
    visit_data = self.visit_data

    assignment_index = visit_data.assigned_image_series_index

    old_assigned_image_series = assignment_index.reject {|series_id, assignment| assignment.nil? or assignment.empty?}.keys

    image_storage_root = Rails.application.config.image_storage_root
    image_storage_root += '/' unless(image_storage_root.end_with?('/'))

    domino_sync_series_ids = []
    
    changed_assignments.each do |required_series_name, series_id|
      series_id = (series_id.blank? ? nil : series_id)
      old_series_id = nil
      visit_data.required_series[required_series_name] = {} if visit_data.required_series[required_series_name].nil?

      if(visit_data.required_series[required_series_name]['image_series_id'])
        old_series_id = visit_data.required_series[required_series_name]['image_series_id'].to_s
        
        assignment_index[old_series_id].delete(required_series_name) unless(old_series_id.blank? or assignment_index[old_series_id].nil?)
      end

      visit_data.required_series[required_series_name]['image_series_id'] = series_id

      assignment_index[series_id] = [] if (series_id and assignment_index[series_id].nil?)
      assignment_index[series_id] << required_series_name unless(series_id.nil? or assignment_index[series_id].include?(required_series_name))

      if(visit_data.required_series[required_series_name]['image_series_id'].nil?)
        FileUtils.rm(image_storage_root + self.required_series_image_storage_path(required_series_name), :force => true)
      else
        FileUtils.rm(image_storage_root + self.required_series_image_storage_path(required_series_name), :force => true)
        FileUtils.ln_sf(series_id, image_storage_root + self.required_series_image_storage_path(required_series_name))
      end

      if(old_series_id != series_id)
        visit_data.required_series[required_series_name]['tqc_state'] = RequiredSeries.tqc_state_sym_to_int(:pending)
        visit_data.required_series[required_series_name].delete('tqc_user_id')
        visit_data.required_series[required_series_name].delete('tqc_date')
        visit_data.required_series[required_series_name].delete('tqc_version')
        visit_data.required_series[required_series_name].delete('tqc_results')
        visit_data.required_series[required_series_name].delete('tqc_comment')
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

    visit_data.reconstruct_assignment_index
    visit_data.save

    schedule_required_series_domino_sync

    domino_sync_series_ids.uniq.each do |series_id|
      image_series = ImageSeries.where(:id => series_id).first
      image_series.schedule_domino_sync unless image_series.nil?
    end
  end

  def reset_tqc_result(required_series_name)
    visit_data = self.visit_data
    return if(visit_data.nil? or visit_data.required_series.nil? or visit_data.required_series[required_series_name].nil?)

    required_series = visit_data.required_series[required_series_name]
    required_series['tqc_state'] = :pending
    required_series.delete('tqc_user_id')
    required_series.delete('tqc_date')
    required_series.delete('tqc_version')
    required_series.delete('tqc_results')
    required_series.delete('tqc_comment')

    visit_data.required_series[required_series_name] = required_series
    visit_data.save

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

    required_series = self.visit_data.required_series[required_series_name]
    return 'No assignment for this required series exists.' if required_series.nil?

    required_series['tqc_state'] = RequiredSeries.tqc_state_sym_to_int((all_passed ? :passed : :issues))
    required_series['tqc_user_id'] = (tqc_user.is_a?(User) ? tqc_user.id : tqc_user)
    required_series['tqc_date'] = (tqc_date.nil? ? Time.now : tqc_date)
    required_series['tqc_version'] = (tqc_version.nil? ? self.study.locked_version : tqc_version)
    required_series['tqc_results'] = result
    required_series['tqc_comment'] = tqc_comment

    visit_data = self.visit_data
    visit_data.required_series[required_series_name] = required_series
    visit_data.save

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

    self.ensure_visit_data_exists
    visit_data = self.visit_data

    self.mqc_state = (all_passed ? :passed : :issues)
    self.mqc_user_id = (mqc_user.is_a?(User) ? mqc_user.id : mqc_user)
    self.mqc_date = (mqc_date.nil? ? Time.now : mqc_date)
    visit_data.mqc_version = (mqc_version.nil? ? self.study.locked_version : mqc_version)
    visit_data.mqc_results = result
    visit_data.mqc_comment = mqc_comment

    visit_data.save
    self.save

    return true
  end

  def mqc_version
    if(self.visit_data and self.visit_data.mqc_version)
      self.visit_data.mqc_version
    elsif(self.study and self.study.locked_version)
      self.study.locked_version
    else
      nil
    end
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
    mqc_spec = self.locked_mqc_spec
    mqc_results = (self.visit_data.nil? ? nil : self.visit_data.mqc_results)
    return nil if mqc_spec.nil? or mqc_results.blank?

    mqc_spec.each do |question|
      question['answer'] = mqc_results[question['id']]
    end
    
    return mqc_spec
  end
  def locked_mqc_spec_with_results
    return mqc_spec_with_results_at_version(self.study.locked_version)
  end
  def mqc_spec_with_results_at_version(version)
    mqc_spec = self.mqc_spec_at_version(version)
    mqc_results = (self.visit_data.nil? ? nil : self.visit_data.mqc_results)
    return nil if mqc_spec.nil? or mqc_results.blank?

    mqc_spec.each do |question|
      question['answer'] = mqc_results[question['id']]
    end
    
    return mqc_spec
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
    end
  end

  def self.audit_trail_event_title_and_severity(event_symbol)
    return case event_symbol
           when :visit_number_change then ['Visit Number Change', :ok]
           when :patient_change then ['Patient Change', :warning]
           when :description_change then ['Description Change', :ok]
           when :visit_type_change then ['Visit Type Change', :warning]
           when :state_change then ['State Change', :warning]
           when :mqc_reset then ['MQC Reset', :warning]
           when :mqc_passed then ['MQC performed, passed', :ok]
           when :mqc_issues then ['MQC performed, issues', :warning]
           when :mqc_state_change then ['MQC State Change', :warning]
           end
  end

  protected

  def reset_mqc
    visit_data = self.visit_data
    unless(visit_data.nil?)
      visit_data.mqc_results = {}
      visit_data.mqc_comment = nil
      visit_data.mqc_version = nil

      visit_data.save
    end

    self.mqc_user_id = nil
    self.mqc_date = nil
    self.mqc_state = :pending

    self.save
  end
  def mqc_to_domino
    self.ensure_visit_data_exists

    result = {}

    result['QCdate'] = {'data' => (self.mqc_date.nil? ? '01-01-0001' : self.mqc_date.strftime('%d-%m-%Y')), 'type' => 'datetime'}
    result['QCperson'] = (self.mqc_user.nil? ? nil : self.mqc_user.name)

    result['QCresult'] = case self.mqc_state
                         when :pending then 'Pending'
                         when :issues then 'Performed, issues present'
                         when :passed then 'Performed, no issues present'
                         end

    result['QCcomment'] = self.visit_data.mqc_comment

    criteria_names = []
    criteria_values = []
    results = self.mqc_spec_with_results_at_version(self.visit_data.mqc_version)
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

  def destroy_visit_data
    VisitData.destroy_all(:visit_id => self.id)
  end  
end
