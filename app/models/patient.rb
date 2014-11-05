class Patient < ActiveRecord::Base
  has_paper_trail

  attr_accessible :session, :subject_id, :session_id

  belongs_to :session
  has_many :form_answers
  has_many :cases
  has_one :patient_data

  validates_uniqueness_of :subject_id, :scope => :session_id  
  
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
    "Session #{session.name}, Subject ID #{subject_id}"
  end

  def patient_data
    PatientData.where(:patient_id => read_attribute(:id)).first
  end

  def self.batch_create_from_csv(csv_file, session)
    csv_options = {
      :col_sep => ',',
      :row_sep => :auto,
      :quote_char => '"',
      :headers => true,
      :converters => [:all, :date],
      :unconverted_fields => true,
    }

    csv = CSV.new(csv_file, csv_options)
    csv.convert do |field|
      if (field.downcase == 'true' or field.downcase == 'yes')
        true
      elsif (field.downcase == 'false' or field.downcase == 'no')
        false
      else
        field
      end
    end
    rows = csv.read

    rows.each do |row|
      subject_id = row.unconverted_fields[row.index('patient')]
      patient = Patient.where(:subject_id => subject_id, :session_id => session.id).first
      patient = Patient.create(:subject_id => subject_id, :session => session) if patient.nil?

      new_patient_data = {}      
      row.headers.each do |field|
        next if field == 'patient'

        new_patient_data[field] = row[field]
      end

      if(patient.patient_data.nil?)
        PatientData.create(:patient => patient, :data => new_patient_data)
      else
        patient.patient_data.update_attributes!(:data => new_patient_data)
      end
    end

    return rows.size
  end

  def self.classify_audit_trail_event(c)
    if(c.keys == ['subject_id'])
      :name_change
    end
  end
  def self.audit_trail_event_title_and_severity(event_symbol)
    return case event_symbol
           when :name_change then ['Subject ID Change', :warning]
           end
  end
end
