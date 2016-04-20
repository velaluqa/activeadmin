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

    def self.classify_mongoid_tracker_event(c)
      if(c.keys == ['data'])
        :data_change
      elsif(c.keys == ['export_history'])
        :export_to_ericav1
      end
    end
    def self.mongoid_tracker_event_title_and_severity(event_symbol)
      return case event_symbol
             when :data_change then ['Patient Data Change', :ok]
             when :export_to_ericav1 then ['Export to ERICAV1', :ok]
             end
    end
  end
end
