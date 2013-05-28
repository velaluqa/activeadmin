module GoodImageMigration
  module GoodImage
    class ExaminationSeries
      include DataMapper::Resource

      storage_names[:goodimage] = 'examination_series'

      property :id, Serial

      property :name, String
      property :comment, String

      property :idx, Integer

      property :compare_parameters_series_id, Integer
      property :parameters_sheet_name, String

      property :modification_timestamp, Time

      belongs_to :series_type, child_key: 'series_type__id'
      has n, :parameter_ranges, 'ParameterRanges', child_key: 'examination_series__id'
      has n, :patient_examination_series, child_key: 'examination_series__id'
    end
  end
end
