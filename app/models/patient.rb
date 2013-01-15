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

  def self.batch_create_from_csv(csv_file, session)
    csv_options = {
      :col_sep => ',',
      :row_sep => :auto,
      :quote_char => '"',
      :headers => true,
      #:converters => nil,
      #:header_converters => nil,
    }

    csv = CSV.new(csv_file, csv_options)
    # csv.convert do |field|
    #   if (field.downcase == 'true' or field.downcase == 'yes')
    #     true
    #   elsif (field.downcase == 'false' or field.downcase == 'no')
    #     false
    #   else
    #     field
    #   end
    # end
    rows = csv.read

    rows.each do |row|
      patient = Patient.where(:subject_id => row['patient'], :session_id => session.id).first
      patient = Patient.create(:subject_id => row['patient'], :session => session, :images_folder => row['patient']) if patient.nil?

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
end
