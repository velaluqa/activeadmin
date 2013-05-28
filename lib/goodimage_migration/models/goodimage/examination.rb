module GoodImageMigration
  module GoodImage
    class Examination
      include DataMapper::Resource

      storage_names[:goodimage] = 'examination'

      property :id, Serial

      property :name, String
      property :comment, String

      property :idx, Integer

      property :modification_timestamp, Time

      belongs_to :study, child_key: 'study__id'
      has n, :segments, child_key: 'examination__id'
      has n, :patient_examinations, child_key: 'examination__id'
    end
  end
end
