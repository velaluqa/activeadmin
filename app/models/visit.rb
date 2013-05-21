require 'domino_document_mixin'

class Visit < ActiveRecord::Base
  include DominoDocument

  has_paper_trail

  attr_accessible :patient_id, :visit_number, :visit_type, :domino_unid
  attr_accessible :patient
  
  belongs_to :patient
  has_many :image_series
  has_one :visit_data

  validates_uniqueness_of :visit_number, :scope => :patient_id
  validates_presence_of :visit_number, :visit_type, :patient_id

  before_destroy do
    self.image_series.each do |is|
      is.visit = nil
      is.save
    end
  end

  after_create :ensure_visit_data_exists
  before_destroy :destroy_visit_data

  def name
    if(patient.nil?)
      "Visit No. #{visit_number}"
    else
      "#{patient.name}, Visit No. #{visit_number}"
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

  def required_series
    return nil if(self.visit_type.nil? or self.study.nil? or not self.study.semantically_valid?)

    study_config = self.study.current_configuration

    return nil if(study_config['visit_types'][self.visit_type].nil? or study_config['visit_types'][self.visit_type]['required_series'].nil?)
    required_series = study_config['visit_types'][self.visit_type]['required_series']

    return required_series
  end
  def required_series_names
    required_series = self.required_series
    return nil if required_series.nil?
    return required_series.keys
  end
  def assigned_required_series(required_series_name)
    self.ensure_visit_data_exists
    return self.visit_data.assigned_required_series[required_series_name]
  end
  def assigned_required_series_map
    self.ensure_visit_data_exists

    return self.visit_data.assigned_required_series
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

  def wado_query
    {:name => "Visit No. #{visit_number}", :image_series => 
      self.image_series.map {|i_s| i_s.wado_query}
    }
  end

  def domino_document_form
    'ImagingVisit'
  end
  def domino_document_query
    {
      'docCode' => 10032,
      'CenterNo' => patient.center.code,
      'PatNo' => patient.domino_patient_no,
      'ericaID' => id,
    }
  end
  def domino_document_fields
    ['id', 'visit_number']
  end
  def domino_document_properties
    {
      'ericaID' => id,
      'Center' => patient.center.name,
      'CenterNo' => patient.center.code,
      'UIDCenter' => patient.center.domino_unid,
      'PatNo' => patient.domino_patient_no,
      'visitNo' => visit_number,
    }
  end

  protected

  def destory_visit_data
    VisitData.destroy_all(:visit_id => self.id)
  end  
end
