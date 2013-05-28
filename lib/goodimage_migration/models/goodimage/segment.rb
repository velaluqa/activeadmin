module GoodImageMigration
  module GoodImage
    class Segment
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'segment'

      property :id, Serial

      property :name, String
      property :comment, String

      property :idx, Integer

      property :select_one_series_type, Boolean
      property :select_no_series, Boolean
      property :seconds_between_times, Integer

      property :parameters_sheet, Binary, lazy: true

      property :modification_timestamp, Time

      belongs_to :examination, child_key: 'examination__id'
      has n, :series_types, child_key: 'segment__id'

      has n, :parameter_to_segments, child_key: 'segment__id'
      has n, :parameters, through: :parameter_to_segments
      has n, :parameter_ranges, 'ParameterRanges', through: :parameter_to_segments
      has n, :patient_examinations, child_key: 'segment__id'
    end
  end
end
