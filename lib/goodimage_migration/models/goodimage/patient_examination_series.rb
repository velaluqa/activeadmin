module GoodImageMigration
  module GoodImage
    class PatientExaminationSeries
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'patient_examination_series'

      property :id, Serial

      property :excluded, Boolean

      property :qc_state, String
      property :idc_state, String
      property :sp_state, String
      property :wf_state, String

      property :comment, String

      property :protocol_deviation, Integer
      property :protocol_deviation_accepted, Boolean
      property :compare_parameters_deviation, Boolean

      property :name, String
      property :label, String

      property :modification_timestamp, Time

      belongs_to :patient_examination, child_key: 'patient_examination__id'
      belongs_to :series_type, child_key: 'series_type__id'
      belongs_to :examination_series, child_key: 'examination_series__id'
      has n, :patient_parameters, child_key: 'patient_examination_series__id'
      has n, :series_image_sets, child_key: 'patient_examination_series__id'

      def underscored_label
        label.gsub(/[- .]/, '_')
      end
    end
  end
end
