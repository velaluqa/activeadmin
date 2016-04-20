module Legacy
  class PatientData
    include Mongoid::Document
    include Mongoid::History::Trackable

    store_in collection: 'patient_data'

    field :patient_id, type: Integer
    field :data, type: Hash, default: {}
    field :export_history, type: Array, default: []

    index patient_id: 1

    track_history :track_create => true, :track_update => true, :track_destroy => true

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
end
