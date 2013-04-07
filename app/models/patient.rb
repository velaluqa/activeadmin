class Patient < ActiveRecord::Base
  has_paper_trail

  attr_accessible :center, :subject_id
  attr_accessible :center_id

  belongs_to :center
  has_many :form_answers
  has_many :cases
  #has_many :visits, :dependent => :destroy
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

  # virtual attribute for pretty names
  def name
    "Center #{center.name}, Subject ID #{subject_id}"
  end

  def patient_data
    PatientData.where(:patient_id => read_attribute(:id)).first
  end
end
