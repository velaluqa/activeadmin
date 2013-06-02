require 'domino_document_mixin'

class ImageSeries < ActiveRecord::Base
  include DominoDocument

  has_paper_trail

  attr_accessible :name, :visit_id, :patient_id, :imaging_date, :domino_unid, :series_number, :state
  attr_accessible :visit, :patient

  belongs_to :visit
  belongs_to :patient
  has_many :images, :dependent => :destroy
  has_one :image_series_data
  
  validates_uniqueness_of :name, :scope => :patient_id
  validates_uniqueness_of :series_number, :scope => :patient_id
  validates_presence_of :name, :patient_id, :imaging_date, :series_number

  scope :not_assigned, where(:visit_id => nil)

  before_save :ensure_study_is_unchanged
  before_save :ensure_visit_is_for_patient
  before_save :update_state

  before_validation :assign_series_number

  after_create :ensure_image_series_data_exists

  before_destroy do
    ImageSeriesData.destroy_all(:image_series_id => self.id)
  end  

  STATE_SYMS = [:imported, :visit_assigned, :required_series_assigned, :not_required]

  def self.state_sym_to_int(sym)
    return ImageSeries::STATE_SYMS.index(sym)
  end
  def state
    return -1 if read_attribute(:state).nil?
    return ImageSeries::STATE_SYMS[read_attribute(:state)]
  end
  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = ImageSeries::STATE_SYMS.index(sym)
    
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

  def wado_query
    {:name => self.name, :images => self.images.order('id ASC')}
  end

  def sample_image
    return nil if self.images.empty?
    return self.images[(self.images.count-1)/2]
  end

  def domino_document_form
    'SOFDinventory'
  end
  def domino_document_query
    {
      'docCode' => 10030,
      'CenterNo' => patient.center.code,
      'imaPatNo' => patient.subject_id,
      'imaSeriesNo' => series_number,
    }
  end
  def domino_document_fields
    ['id', 'imaging_date']
  end
  def domino_document_properties
    properties = {
      'ericaID' => id,
      'Center' => patient.center.name,
      'CenterNo' => patient.center.code,
      'UIDCenter' => patient.center.domino_unid,
      'PatNo' => patient.domino_patient_no,
      'imaPatNo' => patient.subject_id,
      'imaSeriesNo' => series_number,
      'imaDateMan' => imaging_date.strftime('%Y%m%d'),
      'imaDateManual' => {'data' => imaging_date.strftime('%d-%m-%Y'), 'type' => 'datetime'}, # this is utterly ridiculous: sending the date in the corrent format (%Y-%m-%d) leads switched month/day for days where this can work (1-12). sending a completely broken format leads to correct parses... *doublefacepalm*
    }

    properties.merge!(self.dicom_metadata_to_domino)
    properties.merge!(self.properties_to_domino)

    properties
  end
  def update_image_series_properties_in_domino
    self.update_domino_document(self.properties_to_domino)
  end

  def ensure_image_series_data_exists
    if(self.image_series_data.nil?)
      ImageSeriesData.create(:image_series_id => self.id)
    end
  end

  def assigned_required_series
    required_series = []
    return required_series if self.visit.nil?

    self.visit.ensure_visit_data_exists
    if(self.visit.visit_data.assigned_image_series_index and self.visit.visit_data.assigned_image_series_index[self.id.to_s])
      self.visit.visit_data.assigned_image_series_index[self.id.to_s].each do |required_series_name|
        required_series << required_series_name
      end
    end

    return required_series
  end

  protected

  def dicom_metadata_to_domino
    study_config = (self.study.nil? ? nil : self.study.current_configuration)
    result = {}

    unless(images.empty?)
      image = self.sample_image
      
      unless image.nil?
        dicom_meta_header, dicom_metadata = image.dicom_metadata
        

        result['ImageModality'] = (dicom_metadata['0008,0060'].nil? ? '' : dicom_metadata['0008,0060'][:value])

        dicom_imaging_date = dicom_metadata['0008,0023']
        dicom_imaging_date = dicom_metadata['0008,0022'] if dicom_imaging_date.nil?
        dicom_imaging_date = DateTime.strptime(dicom_imaging_date[:value], '%Y%m%d') unless dicom_imaging_date.nil?
        unless(dicom_imaging_date.nil?)
          result['imaDate'] = dicom_imaging_date.strftime('%Y%m%d')
          result['imaDate2'] = dicom_imaging_date.strftime('%d-%m-%Y')
        end

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
  def properties_to_domino
    image_series_data = self.image_series_data
    study_config = (self.study.nil? ? nil : self.study.current_configuration)
    result = {}

    if(study_config and study.semantically_valid? and image_series_data and image_series_data.properties)
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

end
