module GoodImageMigration
  module GoodImage
    class ParameterRanges
      include DataMapper::Resource

      storage_names[:goodimage] = 'parameter_ranges'

      property :id, Serial

      property :minor, String
      property :major, String
      property :formula, Text

      property :modification_timestamp, Time

      belongs_to :examination_series, child_key: 'examination_series__id'
      belongs_to :parameter_to_segment, child_key: 'parameter_to_segment__id'
      has 1, :parameter, through: :parameter_to_segment
      has 1, :segment, through: :parameter_to_segment
      has n, :patient_parameters, child_key: 'parameter_ranges__id'
    end
  end
end
