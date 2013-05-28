module GoodImageMigration
  module GoodImage
    class SeriesType
      include DataMapper::Resource

      storage_names[:goodimage] = 'series_type'

      property :id, Serial

      property :name, String
      property :comment, String

      property :optional, Boolean

      property :idx, Integer

      property :seconds_between_times, Integer
      property :time_format, String

      property :modification_timestamp, Time

      belongs_to :segment, child_key: 'segment__id'
      has n, :examination_series, child_key: 'series_type__id'
      has n, :patient_examinations, child_key: 'series_type__id'
      has n, :patient_examination_series, child_key: 'series_type__id'
    end
  end
end
