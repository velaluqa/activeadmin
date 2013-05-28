module GoodImageMigration
  module GoodImage
    class Center
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'center'

      property :id, Serial
      
      property :internal_id, String
      property :name, String
      property :label, String
      property :comment, String

      property :city, String
      property :country, String
      
      property :modification_timestamp, Time

      has n, :center_to_studies, child_key: 'center__id'
      has n, :studies, through: :center_to_studies
      has n, :patients, through: :center_to_studies
    end
  end
end
