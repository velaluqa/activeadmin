module GoodImageMigration
  module GoodImage
    class CenterToStudy
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'center_to_study'

      property :id, Serial

      property :contact_person, String
      property :comment, String

      property :modification_timestamp, Time

      belongs_to :center, child_key: 'center__id'
      belongs_to :study,  child_key: 'study__id'
      has n, :patients, child_key: 'center_to_study__id'
    end
  end
end
