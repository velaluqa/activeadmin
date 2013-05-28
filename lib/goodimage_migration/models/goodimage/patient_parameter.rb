module GoodImageMigration
  module GoodImage
    class PatientParameter
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'patient_parameter'

      property :id, Serial

      property :value_original, Text, lazy: false
      property :value_corrected, Text, lazy: false
      
      property :protocol_deviation, Boolean

      property :modification_timestamp, Time

      belongs_to :patient_examination_series, child_key: 'patient_examination_series__id'
      belongs_to :parameter, child_key: 'parameter__id'
      belongs_to :parameter_ranges, 'ParameterRanges', child_key: 'parameter_ranges__id'
    end
  end
end
