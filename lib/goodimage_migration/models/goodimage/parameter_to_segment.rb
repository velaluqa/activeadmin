module GoodImageMigration
  module GoodImage
    class ParameterToSegment
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'parameter_to_segment'

      property :id, Serial

      property :idx, Integer

      property :modification_timestamp, Time

      belongs_to :segment, child_key: 'segment__id'
      belongs_to :parameter,  child_key: 'parameter__id'
      has n, :parameter_ranges, 'ParameterRanges', child_key: 'examination_series__id'
    end
  end
end
