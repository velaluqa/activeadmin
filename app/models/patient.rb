require 'domino_document_mixin'

class Patient < ActiveRecord::Base
  include DominoDocument

  has_paper_trail

  attr_accessible :center, :subject_id, :domino_unid
  attr_accessible :center_id

  belongs_to :center
  has_many :form_answers
  has_many :cases
  has_many :visits, :dependent => :destroy
  has_many :image_series, :dependent => :destroy
  has_one :patient_data

  validates_uniqueness_of :subject_id, :scope => :center_id
  validates_presence_of :subject_id
  
  before_destroy do
    unless cases.empty? and form_answers.empty?
      errors.add :base, 'You cannot delete a patient which has cases or form answers associated.' 
      return false
    end

    PatientData.destroy_all(:patient_id => self.id)
  end

  def form_answers
    return FormAnswer.where(:patient_id => self.id)
  end

  def study
    if self.center.nil?
      nil
    else
      self.center.study
    end
  end

  # virtual attribute for pretty names
  def name
    if(center.nil?)
      "Subject ID #{subject_id}"
    else
      "Center #{center.name}, Subject ID #{subject_id}"
    end
  end

  def patient_data
    PatientData.where(:patient_id => read_attribute(:id)).first
  end

  def previous_image_storage_path
    if(self.previous_changes.include?(:center_id))
      previous_center = Center.find(self.previous_changes[:center_id][0])
      
      previous_center.image_storage_path + '/' + self.id.to_s
    else
      image_storage_path
    end
  end
  def image_storage_path
    self.center.image_storage_path + '/' + self.id.to_s
  end

  def wado_query
    {:name => self.name, :visits => self.visits.map {|visit| visit.wado_query} +
      [{:name => 'Unassigned', :image_series => self.image_series.where(:visit_id => nil).map {|i_s| i_s.wado_query}
       }]
    }
  end

  def domino_patient_no
    "#{center.code}#{subject_id}"
  end
  def domino_document_form
    'TrialSubject'
  end
  def domino_document_query
    {
      'docCode' => 10028,
      'CenterNo' => center.code,
      'PatientNo' => domino_patient_no,
    }
  end
  def domino_document_fields
    ['subject_id']
  end
  def domino_document_properties
    return {} if center.nil?

    {
      'Center' => center.name,
      'shCenter' => center.name,
      'CenterNo' => center.code,
      'shCenterNo' => center.code,
      'UIDCenter' => center.domino_unid,
      'PatientNo' => domino_patient_no,
    }
  end
end
