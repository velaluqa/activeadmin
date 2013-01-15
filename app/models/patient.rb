class Patient < ActiveRecord::Base
  attr_accessible :images_folder, :session, :subject_id, :session_id

  belongs_to :session
  has_many :form_answers
  has_one :patient_data

  # virtual attribute for pretty names
  def name
    "Session #{session.name}, Subject ID #{subject_id}"
  end

  def patient_data
    PatientData.where(:patient_id => read_attribute(:id)).first
  end
end
