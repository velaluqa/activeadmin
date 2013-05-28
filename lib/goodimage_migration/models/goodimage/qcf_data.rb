module GoodImageMigration
  module GoodImage
    class QCFData
      include DataMapper::Resource

      storage_names[:goodimage] = 'qcf_data'

      property :id, Serial

      property :scanner_related_problems, Boolean
      property :patient_related_problems, Boolean
      property :other_problems, Boolean
      property :pcf_relevant, Boolean

      property :comment, Text

      property :modification_timestamp, Time

      belongs_to :patient_examination, child_key: 'patient_examination__id'
    end
  end
end
