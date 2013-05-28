module GoodImageMigration
  module GoodImage
    class Patient
      include DataMapper::Resource

      storage_names[:goodimage] = 'patient'

      property :id, Serial
      property :internal_id, String

      property :excluded, Boolean
      property :pilot, Boolean

      property :comment, String

      property :qc_state, String
      property :idc_state, String
      property :fqc_state, String
      property :sp_state, String
      property :wf_state, String

      property :dicom_id, String

      property :name, String
      property :weight, String
      property :sex, String
      property :birth_date, String
      property :size, String
      property :agent, String

      property :modification_timestamp, Time
      property :modification_id, Integer

      property :changes, Boolean

      belongs_to :center_to_study, child_key: 'center_to_study__id'
      has 1, :center, through: :center_to_study
      has 1, :study, through: :center_to_study

      has n, :cds, 'CD', child_key: 'patient__id'

      has n, :patient_examinations, child_key: 'patient__id'
    end
  end
end
