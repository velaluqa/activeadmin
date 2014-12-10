require 'domino_document_mixin'

class ImageSeries < ActiveRecord::Base
  include DominoDocument

  has_paper_trail
  acts_as_taggable

  attr_accessible :name, :visit_id, :patient_id, :imaging_date, :domino_unid, :series_number, :state, :comment
  attr_accessible :visit, :patient

  belongs_to :visit
  belongs_to :patient
  has_many :images, :dependent => :destroy
  has_one :image_series_data
  
  #validates_uniqueness_of :series_number, :scope => :patient_id
  validates_presence_of :name, :patient_id, :imaging_date

  scope :not_assigned, where(:visit_id => nil)

  before_save :ensure_study_is_unchanged
  before_save :ensure_visit_is_for_patient
  before_save :update_state

  #before_validation :assign_series_number

  after_create :ensure_image_series_data_exists

  before_destroy do
    ImageSeriesData.destroy_all(:image_series_id => self.id)
  end  

  STATE_SYMS = [:imported, :visit_assigned, :required_series_assigned, :not_required]

  def self.state_sym_to_int(sym)
    return ImageSeries::STATE_SYMS.index(sym)
  end
  def self.int_to_state_sym(sym)
    return ImageSeries::STATE_SYMS[sym]
  end
  def state
    return -1 if read_attribute(:state).nil?
    return ImageSeries::STATE_SYMS[read_attribute(:state)]
  end
  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    if sym.is_a? Fixnum
      index = sym
    else
      index = ImageSeries::STATE_SYMS.index(sym)
    end
    
    if index.nil?
      throw "Unsupported state"
      return
    end
    
    write_attribute(:state, index)
  end

  def study
    if self.patient.nil?
      nil
    else
      self.patient.study
    end
  end

  def image_series_data
    ImageSeriesData.where(:image_series_id => read_attribute(:id)).first
  end

  def previous_image_storage_path
    if(self.previous_changes.include?(:patient_id) || self.previous_changes.include?(:visit_id))
      previous_patient = (self.previous_changes[:patient_id].nil? ? self.patient : Patient.find(self.previous_changes[:patient_id][0]))
      previous_visit = if self.previous_changes[:visit_id].nil?
                         self.visit
                       elsif self.previous_changes[:visit_id][0].nil?
                         nil
                       else
                         Visit.find(self.previous_changes[:visit_id][0])
                       end

      
      if(previous_visit.nil?)      
        previous_patient.image_storage_path + '/__unassigned/' + self.id.to_s
      else
        previous_visit.image_storage_path + '/' + self.id.to_s
      end
    else
      image_storage_path
    end
  end
  def image_storage_path
    if(self.visit.nil?)
      self.patient.image_storage_path + '/__unassigned/' + self.id.to_s
    else
      self.visit.image_storage_path + '/' + self.id.to_s
    end
  end
  def absolute_image_storage_path
    Rails.application.config.image_storage_root + '/' + self.image_storage_path
  end

  def wado_query
    {:id => self.id, :name => self.name, :images => self.images.order('id ASC')}
  end

  def sample_image
    return nil if self.images.empty?
    return self.images[(self.images.count-1)/2]
  end

  def domino_document_form
    'SeriesInventory'
  end
  def domino_document_query
    {
      'docCode' => 10043,
      'ericaID' => self.id,
    }
  end
  def domino_document_properties(action = :update)
    properties = {
      'ericaID' => id,
      'CenterNo' => patient.center.code,
      'PatNo' => patient.domino_patient_no,
      'VisitNo' => (self.visit.nil? ? nil : self.visit.visit_number),
      'DateImaging' => {'data' => imaging_date.strftime('%d-%m-%Y'), 'type' => 'datetime'}, # this is utterly ridiculous: sending the date in the corrent format (%Y-%m-%d) leads switched month/day for days where this can work (1-12). sending a completely broken format leads to correct parses... *doublefacepalm*
      'SeriesDescription' => self.name,
      'AssignedTo' => self.assigned_required_series.join("\n"),      
    }

    properties.merge!(self.dicom_metadata_to_domino)
    properties.merge!(self.properties_to_domino)

    properties
  end

  def domino_sync
    self.ensure_domino_document_exists

    unless(self.visit.nil?)
      # the reload call is here to work around a race condition in the domino sync
      # when an image series is re/unassigned on a visit that had mQC completed, the image series sync is started first
      # it then starts its visit sync, possibly after the visit was modified and had its mQC results reset
      # this visit instance would then contain the old values, including the mQC details
      # therefor, we reload it here before we sync it, to make sure we have the most up-to-date values
      self.visit.reload
      self.visit.domino_sync

      assigned_required_series_names = self.assigned_required_series || []      
      assigned_required_series_names.each do |as_name|
        RequiredSeries.new(self.visit, as_name).domino_sync
      end
    end
  end

  def ensure_image_series_data_exists
    if(self.image_series_data.nil?)
      ImageSeriesData.create(:image_series_id => self.id)
    end
  end

  def assigned_required_series
    return [] if self.visit.nil?

    self.visit.ensure_visit_data_exists
    if(self.visit.visit_data.assigned_image_series_index and self.visit.visit_data.assigned_image_series_index[self.id.to_s])
      return self.visit.visit_data.assigned_image_series_index[self.id.to_s]
    end

    return []
  end
  def change_required_series_assignment(new_assignment)
    return if self.visit.nil?
    changes = {}
    
    current_assignment = self.assigned_required_series
    
    pp current_assignment
    pp new_assignment
    
    (current_assignment-new_assignment).each do |unassigned_required_series|
      changes[unassigned_required_series] = nil
    end
    (new_assignment-current_assignment).each do |assigned_required_series|
      changes[assigned_required_series] = self.id.to_s
    end

    self.visit.change_required_series_assignment(changes)
  end

  def dicom_metadata_to_domino
    study_config = (self.study.nil? ? nil : self.study.locked_configuration)
    result = {}

    unless(images.empty?)
      image = self.sample_image
      
      unless image.nil?
        dicom_meta_header, dicom_metadata = image.dicom_metadata
        
        if(study_config and study.semantically_valid?)
          dicom_tag_names = []
          dicom_values = []
          study_config['domino_integration']['dicom_tags'].each_with_index do |tag, i|
            dicom_values << (dicom_metadata[tag['tag']].nil? ? 'N/A' : dicom_metadata[tag['tag']][:value]).to_s
            dicom_tag_names << tag['label'].to_s
          end          

          result['DICOMTagNames'] = dicom_tag_names.join("\n")
          result['DICOMValues'] = dicom_values.join("\n")
        end
      end
    end
    
    return result
  end

  protected

  def properties_to_domino
    image_series_data = self.image_series_data
    properties_version = if(image_series_data.nil? and self.study.nil?)
                           nil
                         elsif(image_series_data.nil? or image_series_data.properties_version.blank?)
                           self.study.locked_version
                         else
                           image_series_data.properties_version
                         end
    study_config = (self.study.nil? or image_series_data.nil? ? nil : self.study.configuration_at_version(properties_version))
    result = {}

    if(study_config and study.semantically_valid_at_version?(properties_version) and image_series_data and image_series_data.properties)
      properties_spec = study_config['image_series_properties']
      property_names = []
      property_values = []

      processed_properties = []

      unless(properties_spec.nil?)
        properties_spec.each do |property|
          property_names << property['label']

          raw_value = image_series_data.properties[property['id']]
          value = case property['type']
                  when 'string'
                    raw_value
                  when 'bool'
                    if(raw_value.nil?)
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

      image_series_data.properties.each do |id, value|
        next if processed_properties.include?(id)
        property_names << id.to_s
        property_values << (value.blank? ? 'Not set' : value.to_s)
      end

      result = {'PropertyNames' => property_names.join("\n"), 'PropertyValues' => property_values.join("\n")}
    end

    return result
  end

  def ensure_study_is_unchanged
    if(self.patient_id_changed? and not self.patient_id_was.nil?)
      old_patient = Patient.find(self.patient_id_was)

      if(old_patient.study != self.patient.study)
        self.errors[:patient] << 'An image series cannot be reassigned to a patient in a different study.'
        return false
      end
    end

    return true
  end

  def ensure_visit_is_for_patient
    if(self.visit && self.visit.patient != self.patient)
      self.errors[:visit] << 'The visits patient is different from this image series\' patient'
      false
    else
      true
    end
  end

  def assign_series_number
    if(self.new_record? and self.series_number.nil? and self.patient)
      self.series_number = self.patient.next_series_number
    end
  end

  def update_state
    if(visit_id_changed?)
      old_visit_id = changes[:visit_id][0]
      new_visit_id = changes[:visit_id][1]

      if(not old_visit_id.nil? and new_visit_id.nil?)
        self.state = :imported
      elsif( (old_visit_id.nil? and not new_visit_id.nil? and state == :imported))
        self.state = :visit_assigned
      end
    end
  end

  # fake attributes for the somewhat laborious implementation of visit assignment changes
  def force_update
    nil
  end
  def force_update=(val)
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

    if(c.keys == ['name'])
      :name_change
    elsif(c.keys == ['comment'])
      :comment_change
    elsif(c.keys == ['center_id'])
      :center_change
    elsif(c.keys == ['imaging_date'])
      :imaging_date_change
    elsif(c.keys == ['series_number'])
      :series_number_change
    elsif(c.keys == ['visit_id'])
      :visit_assignment_change
    elsif(c.keys == ['patient_id'])
      :patient_change
    elsif(c.include?('state'))
      case [int_to_state_sym(c['state'][0].to_i), c['state'][1]]
      when [:imported, :visit_assigned], [:not_required, :visit_assigned] then :visit_assigned
      when [:visit_assigned, :required_series_assigned], [:not_required, :required_series_assigned] then :required_series_assigned
      when [:required_series_assigned, :visit_assigned] then :required_series_unassigned
      when [:visit_assigned, :imported], [:required_series_assigned, :imported] then :visit_unassigned
      when [:imported, :not_required], [:visit_assigned, :not_required], [:required_series_assigned, :not_required] then :marked_not_required
      when [:not_required, :imported] then :unmarked_not_required
      end
    end
  end
  def self.audit_trail_event_title_and_severity(event_symbol)
    return case event_symbol
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
           end
  end
end
