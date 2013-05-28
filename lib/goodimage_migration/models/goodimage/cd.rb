module GoodImageMigration
  module GoodImage
    class CD
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'cd'

      property :id, Serial

      property :internal_id, String

      property :date, Date

      property :modification_timestamp, Time

      belongs_to :patient, child_key: 'patient__id'
    end
  end
end
