module GoodImageMigration
  module GoodImage
    class Report
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'report'

      property :id, Serial

      property :pdf_data, Binary, lazy: true

      property :filename, String
      property :type, String

      # this is actually an association, but since we do not need the users, we don't have a corresponding model
      property :user__id, Integer

      property :modification_timestamp, Time

      belongs_to :patient_examination, child_key: 'patient_examination__id'
    end
  end
end
