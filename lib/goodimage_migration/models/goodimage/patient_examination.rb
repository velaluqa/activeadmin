module GoodImageMigration
  module GoodImage
    class PatientExamination
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'patient_examination'

      property :id, Serial

      property :excluded, Boolean

      property :qc_state, String
      property :idc_state, String
      property :fqc_state, String
      property :sp_state, String
      property :wf_state, String

      property :comment, String
      property :device, String

      property :major_deviation_checkbox, Boolean
      property :major_deviation, Boolean

      property :modification_timestamp, Time

      belongs_to :patient, child_key: 'patient__id'
      belongs_to :examination, child_key: 'examination__id'
      belongs_to :segment, child_key: 'segment__id'
      belongs_to :series_type, child_key: 'series_type__id', required: false
      has n, :patient_examination_series, child_key: 'patient_examination__id'
      has n, :qcf_data, 'QCFData', child_key: 'patient_examination__id'
      has n, :reports, child_key: 'patient_examination__id'
    end
  end
end
