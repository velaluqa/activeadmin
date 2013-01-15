class PatientData
  include Mongoid::Document

  field :patient_id, type: Integer
  field :data, type: Hash

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

  def to_yaml
    data.to_yaml(:indentation => 2, :line_width => -1, :canonical => false)
  end
end
