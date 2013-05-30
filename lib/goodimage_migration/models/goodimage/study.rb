module GoodImageMigration
  module GoodImage
    class Study
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

      storage_names[:goodimage] = 'study'

      property :id, Serial
      
      property :internal_id, String
      property :name, String
      property :label, String
      property :description, String

      property :length_center_internal_id, Integer
      property :length_patient_internal_id, Integer
      property :length_cd_internal_id, Integer

      property :title, String
      property :drug, String
      property :phase, String

      property :disable, Integer
      
      property :modification_timestamp, Time
      property :modification_id, Integer

      property :tags_for_serie, String
      property :tags_for_anonym, String
      property :compare_exclude_tags, String

      property :maximal_series_qcf, Integer
      property :release_br, Boolean

      property :pcf_report, String
      property :qcf_report, String
      property :icf_report, String

      property :generate_media_number, Boolean
      property :media, String

      property :patients_per_center_parameters, String

      has n, :center_to_studies, child_key: 'study__id'
      has n, :centers, through: :center_to_studies
      has n, :patients, through: :center_to_studies
      
      has n, :examinations, child_key: 'study__id'

      def migration_children
        return self.center_to_studies
      end
    end
  end
end
