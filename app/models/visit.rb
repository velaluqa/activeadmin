require 'domino_document_mixin'

class Visit < ActiveRecord::Base
  include DominoDocument

  has_paper_trail

  attr_accessible :patient_id, :visit_number, :visit_type, :domino_unid
  attr_accessible :patient
  
  belongs_to :patient
  has_many :image_series

  validates_uniqueness_of :visit_number, :scope => :patient_id
  validates_presence_of :visit_number, :visit_type, :patient_id

  before_destroy do
    self.image_series.each do |is|
      is.visit = nil
      is.save
    end
  end

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
end
