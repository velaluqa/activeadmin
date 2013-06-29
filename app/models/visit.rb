require 'domino_document_mixin'
require 'git_config_repository'

class Visit < ActiveRecord::Base
  include DominoDocument

  has_paper_trail

  attr_accessible :patient_id, :visit_number, :description, :visit_type, :domino_unid
  attr_accessible :patient
  
  belongs_to :patient
  has_many :image_series
  has_one :visit_data

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

  def visit_data
    VisitData.where(:visit_id => read_attribute(:id)).first    
  end
  def ensure_visit_data_exists
    VisitData.create(:visit_id => self.id) if self.visit_data.nil?
  end

  def required_series_specs
    return nil if(self.visit_type.nil? or self.study.nil? or not self.study.semantically_valid?)

    study_config = self.study.current_configuration

    return nil if(study_config['visit_types'][self.visit_type].nil? or study_config['visit_types'][self.visit_type]['required_series'].nil?)
    required_series = study_config['visit_types'][self.visit_type]['required_series']

    return required_series
  end
  def required_series_names
    required_series_specs = self.required_series_specs
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
  end
  def domino_sync_required_series
    self.required_series_objects.each do |required_series|
      required_series.ensure_domino_document_exists
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
    RequiredSeries.new(self, new_name).ensure_domino_document_exists
  end

  def change_required_series_assignment(changed_assignments)
    self.ensure_visit_data_exists
    visit_data = self.visit_data

    assignment_index = visit_data.assigned_image_series_index

    old_assigned_image_series = assignment_index.reject {|series_id, assignment| assignment.nil? or assignment.empty?}.keys

    image_storage_root = Rails.application.config.image_storage_root
    image_storage_root += '/' unless(image_storage_root.end_with?('/'))
    
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
      end
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

    domino_sync_required_series
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

    visit_data.required_series[required_series_name] = required_series
    visit_data.save

    RequiredSeries.new(self, required_series_name).ensure_domino_document_exists
  end
  def set_tqc_result(required_series_name, result, tqc_user, tqc_date = nil, tqc_version = nil)
    required_series_specs = self.required_series_specs
    return 'No valid study configuration exists.' if required_series_specs.nil?

    tqc_spec = (required_series_specs[required_series_name].nil? ? nil : required_series_specs[required_series_name]['tqc'])
    return 'No tQC config for this required series exists.' if tqc_spec.nil?

    all_passed = true
    tqc_spec.each do |spec|
      all_passed &&= (result[spec['id']] == true)
    end

    required_series = self.visit_data.required_series[required_series_name]
    return 'No assignment for this required series exists.' if required_series.nil?

    required_series['tqc_state'] = RequiredSeries.tqc_state_sym_to_int((all_passed ? :passed : :issues))
    required_series['tqc_user_id'] = (tqc_user.is_a?(User) ? tqc_user.id : tqc_user)
    required_series['tqc_date'] = (tqc_date.nil? ? Time.now : tqc_date)
    required_series['tqc_version'] = (tqc_version.nil? ? GitConfigRepository.new.current_version : tqc_version)
    required_series['tqc_results'] = result

    visit_data = self.visit_data
    visit_data.required_series[required_series_name] = required_series
    visit_data.save

    # TODO: send results to Domino?
    
    RequiredSeries.new(self, required_series_name).ensure_domino_document_exists
    return true
  end

  protected

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
