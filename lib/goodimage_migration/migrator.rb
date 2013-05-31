require 'goodimage_migration/models'

module GoodImageMigration
  class Migrator

    def initialize(config)
      @imaging_date_parameter_ids = GoodImageMigration::GoodImage::Parameter.all(:dicom => ['00080023', '00080022']).map {|parameter| parameter.id}

      @config = config
      @goodimage_image_storage_root = config['goodimage_image_storage']
      @goodimage_image_storage_root += '/' unless @goodimage_image_storage_root.end_with?('/')
    end
    
    def migrate(goodimage_resource, erica_parent_resource)
      Rails.logger.info "Starting migration for #{goodimage_resource.inspect} (with parent resource #{erica_parent_resource.inspect}"
      erica_resource = case goodimage_resource
                       when GoodImage::Study
                         self.migrate_resource(goodimage_resource, ::Study) {|goodimage_study, erica_study| update_study(goodimage_study, erica_study)}
                       when GoodImage::CenterToStudy
                         self.migrate_resource(goodimage_resource, ::Center) {|goodimage_study, erica_study| update_center(goodimage_study, erica_study, erica_parent_resource)}
                       when GoodImage::Patient
                         self.migrate_resource(goodimage_resource, ::Patient, Proc.new {|goodimage_resource, erica_resource| update_patient_data(goodimage_resource, erica_resource)}) {|goodimage_study, erica_study| update_patient(goodimage_study, erica_study, erica_parent_resource)}
                       when GoodImage::SeriesImageSet
                         self.migrate_resource(goodimage_resource, ::ImageSeries) {|goodimage_study, erica_study| update_image_series(goodimage_study, erica_study, erica_parent_resource)}
                       when GoodImage::PatientExamination
                         self.migrate_resource(goodimage_resource, ::Visit) {|goodimage_study, erica_study| update_visit(goodimage_study, erica_study, erica_parent_resource)}
                       when GoodImage::Image
                         self.migrate_resource(goodimage_resource, ::Image, Proc.new {|goodimage_resource, erica_resource| copy_image_file(goodimage_resource, erica_resource)}) {|goodimage_study, erica_study| update_image(goodimage_study, erica_study, erica_parent_resource)}
                       else
                         nil
                       end

      if(erica_resource.nil?)
        Rails.logger.fatal "Migration of GoodImage resource #{goodimage_resource.inspect} failed, aborting migration process."
        return false
      end
      success = true
      
      children = goodimage_resource.respond_to?(:migration_children) ? goodimage_resource.migration_children : []
      children.each do |child|
        pp child
        success &&= migrate(child, erica_resource)
        break unless success
      end

      return success
    end
    
    protected

    def update_study(goodimage_study, erica_study)
      erica_study.name = goodimage_study.internal_id
    end
    def update_center(goodimage_center_to_study, erica_center, erica_parent_study)
      erica_center.name = goodimage_center_to_study.center.name
      erica_center.code = goodimage_center_to_study.center.internal_id

      erica_center.study_id = erica_parent_study.id
    end
    def update_patient(goodimage_patient, erica_patient, erica_parent_center)
      erica_patient.subject_id = goodimage_patient.internal_id
      erica_patient.images_folder = goodimage_patient.internal_id

      erica_patient.center_id = erica_parent_center.id

    end
    def update_patient_data(goodimage_patient, erica_patient)
      erica_patient_data = erica_patient.patient_data
      if(erica_patient_data.nil?)
        erica_patient_data = ::PatientData.new
        erica_patient_data.patient_id = erica_patient.id
      end
      erica_patient_data.data = {}

      erica_patient_data.data['comment'] = goodimage_patient.comment
      erica_patient_data.data['name'] = goodimage_patient.name
      erica_patient_data.data['weight'] = goodimage_patient.weight
      erica_patient_data.data['sex'] = goodimage_patient.sex
      erica_patient_data.data['birth_date'] = goodimage_patient.birth_date
      erica_patient_data.data['size'] = goodimage_patient.size
      erica_patient_data.data['agent'] = goodimage_patient.agent
      
      erica_patient_data.save
    end
    def update_visit(goodimage_patient_examination, erica_visit, erica_parent_patient)
      erica_visit.visit_number = goodimage_patient_examination.examination.idx

      erica_visit.patient_id = erica_parent_patient.id
    end
    def update_image_series(goodimage_series_image_set, erica_image_series, erica_parent_patient)
      erica_image_series.name = goodimage_series_image_set.proper_series_name
      erica_image_series.series_number = goodimage_series_image_set.series_number
      erica_image_series.imaging_date = goodimage_series_image_set.imaging_date(@imaging_date_parameter_ids) || Date.new(1900,01,01)

      erica_image_series.patient_id = erica_parent_patient.id

      assigned_equivalent_series = goodimage_series_image_set.equivalent_series.reject{|series| series.id == goodimage_series_image_set.id or series.patient_examination_series.nil?}.first
      unless(assigned_equivalent_series.nil?)
        migration_mapping = Migration::Mapping.find_by_goodimage_resource(assigned_equivalent_series.patient_examination_series.patient_examination).first
        if(migration_mapping)
          erica_parent_visit_id = migration_mapping.target_id
          
          erica_image_series.visit_id = erica_parent_visit_id
          erica_image_series.state = :visit_assigned

          # TODO: required series assignment
          # * add assigned_equivalent_series.patient_examination_series.patient_examination.examination.name as visit type (visit_type)
          # * add assigned_equivalent_series.patient_examination_series.name (or .label) as required series for visit_type (required_series_name)
          # * assign erica_image_series to required series (VisitData.required_series[required_series_name] = {'id' => erica_image_series.id})
          # * set tqc results: VisitData.required_series[required_series_name]['tqc_state'] = :passed/:issues
        end
      end      
    end
    def update_image(goodimage_image, erica_image, erica_parent_image_series)
      erica_image.image_series_id = erica_parent_image_series.id
    end
    def copy_image_file(goodimage_image, erica_image)
      begin
        FileUtils.cp(@goodimage_image_storage_root + goodimage_image.file_path, erica_image.absolute_image_storage_path, :verbose => true, :preserve => true)
      rescue SystemCallError => e
        Rails.logger.error "Failed to copy image file for #{goodimage_image.inspect} from #{@goodimage_image_storage_root + goodimage_image.file_path} to #{erica_image.absolute_image_storage_path}:"
        Rails.logger.error e.message
        return false
      end
      return true
    end

    def migrate_resource(goodimage_resource, erica_resource_class, aftersave_proc = nil, &block)
      Rails.logger.debug "GoodImage Resource: #{goodimage_resource.inspect}"

      resource_type = GoodImageMigration::Migration::Mapping.resource_type(goodimage_resource)
      erica_resource, migration_mapping = erica_resource_from_mapping(resource_type, goodimage_resource.id)
      if(erica_resource == true)
        return erica_resource
      elsif(erica_resource.nil?)
        erica_resource = erica_resource_class.new
      end

      # update values
      yield(goodimage_resource, erica_resource)

      Rails.logger.debug "Created/Updated ERICA resource: #{erica_resource.inspect}"

      unless(erica_resource.save)
        Rails.logger.fatal "Failed to save ERICA resource, aborting"
        return nil
      end

      unless(aftersave_proc.nil?)
        aftersave_proc.call(goodimage_resource, erica_resource)
      end

      new_modification_timestamp = goodimage_resource.respond_to?(:modification_timestamp) ? goodimage_resource.modification_timestamp : Time.now
      if(migration_mapping.nil?)
        migration_mapping = Migration::Mapping.create(:type => resource_type, :source_id => goodimage_resource.id, :target_id => erica_resource.id, :migration_timestamp => new_modification_timestamp)
      else
        migration_mapping.migration_timestamp = new_modification_timestamp
      end
      if(migration_mapping.save)
        return erica_resource
      else
        return nil
      end
    end

    def erica_resource_from_mapping(type, goodimage_id)
      erica_resource = nil
      migration_mapping = Migration::Mapping.first(:type => type, :source_id => goodimage_id)
      if(migration_mapping)
        erica_resource_id = migration_mapping.target_id
        Rails.logger.info "Found an existing migration mapping for this #{type}, ERICA #{type} has ID #{erica_resource_id}"
        unless(migration_mapping.update_required?)
          Rails.logger.info "ERICA #{type} is up to date, no migration required."
          return [true, migration_mapping]
        end

        erica_resource = migration_mapping.target
        if(erica_resource.nil?)
          Rails.logger.warning "Could not find existing #{type} in ERICA, creating a new one..."
        else
          Rails.logger.info "Found the existing #{type} in ERICA, updating values..."
          Rails.logger.debug "Existing ERICA #{type}: #{erica_resource.inspect}"
        end
      else
        Rails.logger.info "No existing migration mapping for this #{type}, creating new #{type} in ERICA..."
      end

      return [erica_resource, migration_mapping]
    end
  end
end
