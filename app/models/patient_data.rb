class PatientData
  include Mongoid::Document

  field :patient_id, type: Integer
  field :data, type: Hash, default: {}

  index patient_id: 1

  def patient
    begin
      return Patient.find(read_attribute(:patient_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def patient=(patient)
    write_attribute(:patient_id, patient.id)
  end
end
