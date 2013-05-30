module GoodImageMigration
  module GoodImage
    class Patient
      include DataMapper::Resource

      def self.default_repository_name
        :goodimage
      end

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

      def full_internal_id
        return nil if(self.internal_id.blank? or self.center.nil? or self.study.nil?)

        return "#{self.study.internal_id}_#{self.center.internal_id}_#{self.internal_id}"
      end
      # returns all original series, not assigned onces
      def series_image_sets
        GoodImageMigration::GoodImage::SeriesImageSet.all(:name.like => self.full_internal_id+'_%', :order => [:name.asc], :original => true)
      end

      def migration_children
        return self.patient_examinations.to_a + self.series_image_sets.to_a
      end
    end
  end
end
