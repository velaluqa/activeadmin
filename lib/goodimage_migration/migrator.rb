require 'goodimage_migration/models'
require 'git_config_repository'

module GoodImageMigration
  class Migrator

    def initialize(config, number_of_studies = 1)
      @imaging_date_parameter_ids = GoodImageMigration::GoodImage::Parameter.all(:dicom => ['00080023', '00080022']).map {|parameter| parameter.id}

      @config = config
      @goodimage_image_storage_root = config['goodimage_image_storage']
      @goodimage_image_storage_root += '/' unless @goodimage_image_storage_root.end_with?('/')      
      @rails_image_storage_root = Rails.application.config.image_storage_root
      @rails_image_storage_root += '/' unless(@rails_image_storage_root.end_with?('/'))

      reset_counters(number_of_studies)
    end

    def copy_missing_images
      images_count = Image.count
      Rails.logger.info "Checking #{images_count} ERICA Images for missing files"

      count = 0
      missing_count = 0
      Image.find_each do |erica_image|
        count += 1
        print count.to_s+'/'+missing_count.to_s+'..' if(count % 1000 == 0)
        
        next if erica_image.file_is_present?
        missing_count += 1

        goodimage_image = goodimage_resource_from_mapping('image', erica_image.id)
        next if goodimage_image.nil?

        copy_image_file(goodimage_image, erica_image)
      end
      puts
      Rails.logger.info "Finished, #{missing_count} images were missing"
    end
    
    def migrate(goodimage_resource, erica_parent_resource)
      Rails.logger.info "Starting migration for #{goodimage_resource.inspect}"
      if(goodimage_resource.class == GoodImage::Study)
        initialize_study_migration_state(goodimage_resource)
      end

      erica_resource = case goodimage_resource
                       when GoodImage::Study
                         set_max_counters(goodimage_resource)
                         update_counters(:studies)
                         print_counters                         
                         self.migrate_resource(goodimage_resource, ::Study) {|goodimage_study, erica_study| update_study(goodimage_study, erica_study)}
                       when GoodImage::CenterToStudy
                         set_max_counters(goodimage_resource)
                         update_counters(:centers)
                         print_counters
                         self.migrate_resource(goodimage_resource, ::Center) {|goodimage_study, erica_study| update_center(goodimage_study, erica_study, erica_parent_resource)}
                       when GoodImage::Patient
                         update_counters(:patients)
                         print_counters
                         self.migrate_resource(goodimage_resource, ::Patient, Proc.new {|goodimage_resource, erica_resource| update_patient_data(goodimage_resource, erica_resource)}) {|goodimage_study, erica_study| update_patient(goodimage_study, erica_study, erica_parent_resource)}
                       when GoodImage::SeriesImageSet
                         self.migrate_resource(goodimage_resource, ::ImageSeries, Proc.new {|goodimage_resource, erica_resource| update_required_series_assignment(goodimage_resource, erica_resource)}) {|goodimage_study, erica_study| update_image_series(goodimage_study, erica_study, erica_parent_resource)}
                       when GoodImage::PatientExamination
                         self.migrate_resource(goodimage_resource, ::Visit, Proc.new {|goodimage_resource, erica_resource| reset_visit_data(goodimage_resource, erica_resource)}) {|goodimage_study, erica_study| update_visit(goodimage_study, erica_study, erica_parent_resource)}
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

      if(goodimage_resource.class == GoodImage::Study)
        write_initial_study_config(erica_resource)
      end
      
      children = goodimage_resource.respond_to?(:migration_children) ? goodimage_resource.migration_children : []
      children.each do |child|
        success &&= migrate(child, erica_resource)
        break unless success
      end

      if(goodimage_resource.class == GoodImage::Study and success)
        add_visit_types_to_erica_study_config(erica_resource)
        find_visits_in_domino(erica_resource)
      end
      return success
    end

    protected

    def reset_counters(number_of_studies)
      @counters = {
        studies: 0,
        centers: 0,
        patients: 0
      }
      @max_counters = {
        studies: number_of_studies,
        centers: -1,
        patients: -1
      }
    end
    def set_max_counters(goodimage_resource)
      case goodimage_resource
      when GoodImage::Study
        @max_counters[:centers] = goodimage_resource.center_to_studies.count
      when GoodImage::CenterToStudy
        @max_counters[:patients] = goodimage_resource.patients.count
      end
    end
    def update_counters(type)
      @counters[type] += 1

      case type
      when :studies
        @counters[:centers] = 0
        @counters[:patients] = 0
      when :centers
        @counters[:patients] = 0
      end
    end
    def print_counters
      print "Currently migrating study #{@counters[:studies]}/#{@max_counters[:studies]}"
      print ", center #{@counters[:centers]}/#{@max_counters[:centers]}" unless(@counters[:centers] == 0)
      print ", patient #{@counters[:patients]}/#{@max_counters[:patients]}" unless(@counters[:patients] == 0)

      puts ".."
    end
    
    def initialize_study_migration_state(goodimage_study)
      unless(@config['study_configs'][goodimage_study.internal_id].blank?)
        @study_config = YAML.load_file(@config['study_configs'][goodimage_study.internal_id])
        @study_config['visit_types'] = {}
      else
        @study_config = {
          'visit_types' => {},
          'domino_integration' => {'dicom_tags' => []},
          'image_series_properties' => []
        }
      end
    end
    def write_initial_study_config(erica_study)
      config_file = Tempfile.new(['study_config_'+erica_study.id.to_s, '.yml'])
      
      config_file.write(@study_config.to_yaml)
      config_file.close
      
      repo = GitConfigRepository.new
      repo.update_config_file(erica_study.relative_config_file_path, config_file.path, nil, "New configuration file for study #{erica_study.id}")      
    end
    def add_visit_types_to_erica_study_config(erica_study)
      begin
        File.open(erica_study.config_file_path, 'w') do |f|
          f.write(@study_config.to_yaml)
        end
        repo = GitConfigRepository.new
        repo.update_path(erica_study.relative_config_file_path, nil, "Adding automatically generated visit types based on GoodImage migration for study #{erica_study.id}")
      rescue Exception => e
        Rails.logger.error "Failed to update the study config for study #{erica_studyid}"
        return
      end
    end

    def find_visits_in_domino(erica_study)
      return unless erica_study.domino_integration_enabled?
      
      @domino_integration_client = DominoIntegrationClient.new(erica_study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
      if(@domino_integration_client.nil?)
        Rails.logger.fatal "Failed to communicate with Domino server at #{erica_study.domino_db_url}, can't assign visits to Domino documents."
        return
      end

      visits = erica_study.visits

      puts "Attempting to link #{visits.size} visits to their corresponding Domino documents via SOFDinventory documents.."

      visits.each_with_index do |visit, index|
        find_visit_in_domino(visit)
        print (index+1).to_s+'..' if((index+1) % 10 == 0)
      end

      puts 'done'

      @domino_integration_client = nil
    end
    def find_visit_in_domino(erica_visit)
      return unless erica_visit.domino_unid.nil?

      visit_domino_unid = nil

      erica_visit.image_series.each do |image_series|
        image_series_domino_document = image_series.domino_document
        next if image_series_domino_document.nil?

        patient_number = image_series_domino_document['PatNo']
        next if patient_number.blank?

        imaging_date_raw = if image_series_domino_document['imaDateManual'].blank?
                         image_series_domino_document['imaDate2']
                       else
                         image_series_domino_document['imaDateManual']
                       end
        next if imaging_date_raw.blank?
        begin
          imaging_date = DateTime.strptime(imaging_date_raw, '%Y-%m-%dT%H:%M:%SZ')
        rescue Exception => e
          Rails.logger.warning "Failed to parse imaging date (#{imaging_date_raw}) for visit #{erica_visit}: #{e.message}"
          imaging_date = nil
        end
        next if imaging_date.nil?

        # this is a bit of a hack
        # Domino returns dates that are in some weird way time-zone corrected
        # problem is: the time zone offset isn't returned
        # usually (CET/CEST), the offset is up to two hours back, so we simply check whether the time is actually in the last two hours of the day and if it is, we go one day ahead
        if(imaging_date.hour >= 22)
          imaging_date += 1.day
        end
        imaging_date_string = imaging_date.strftime('%d/%m/%Y')

        matching_visits = @domino_integration_client.find_document({'docCode' => 10032, 'PatNo' => patient_number, 'VisitDate' => imaging_date_string})
        if(matching_visits.is_a?(Array) and not matching_visits.empty?)
          visit_domino_unid = matching_visits[0]['@unid']
          break unless visit_domino_unid.blank?
        end        
      end

      unless(visit_domino_unid.blank?)
        erica_visit.set_domino_unid(visit_domino_unid)
      end
    end

    def update_study(goodimage_study, erica_study)
      erica_study.name = goodimage_study.internal_id

      erica_study.domino_db_url = @config['domino_urls'][goodimage_study.internal_id] unless @config['domino_urls'].nil? or @config['domino_urls'][goodimage_study.internal_id].blank?
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

      erica_visit.visit_type = goodimage_patient_examination.examination.underscored_name
      @study_config['visit_types'][erica_visit.visit_type] = {'required_series' => {}} if @study_config['visit_types'][erica_visit.visit_type].nil?
    end
    def reset_visit_data(goodimage_patient_examination, erica_visit)
      erica_visit.ensure_visit_data_exists
      erica_visit_data = erica_visit.visit_data

      erica_visit_data.required_series = {}
      erica_visit_data.assigned_image_series_index = {}
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
        end
      end
    end
    def update_required_series_assignment(goodimage_series_image_set, erica_image_series)
      return if erica_image_series.visit.nil?

      assigned_equivalent_series = goodimage_series_image_set.equivalent_series.reject{|series| series.id == goodimage_series_image_set.id or series.patient_examination_series.nil?}.first
      unless(assigned_equivalent_series.nil?)
        erica_required_series_name = assigned_equivalent_series.patient_examination_series.underscored_name
        erica_parent_visit = erica_image_series.visit
    
        unless(erica_parent_visit.visit_type.blank? or @study_config['visit_types'][erica_parent_visit.visit_type].nil?)
          @study_config['visit_types'][erica_parent_visit.visit_type]['required_series'][erica_required_series_name] = {'tqc' => []} if @study_config['visit_types'][erica_parent_visit.visit_type]['required_series'][erica_required_series_name].nil?
        end

        erica_parent_visit.ensure_visit_data_exists
        erica_parent_visit_data = erica_parent_visit.visit_data
        
        # TODO: set correct tQC state
        erica_parent_visit_data.required_series[erica_required_series_name] = {'image_series_id' => erica_image_series.id, 'tqc_state' => ::RequiredSeries.tqc_state_sym_to_int(:pending), 'tqc_results' => {}}
        erica_parent_visit_data.assigned_image_series_index[erica_image_series.id] = [erica_required_series_name]

        erica_parent_visit_data.save

        erica_image_series.state = :required_series_assigned
        erica_image_series.save

        FileUtils.rm(@rails_image_storage_root + erica_parent_visit.required_series_image_storage_path(erica_required_series_name), :force => true)
        FileUtils.ln_sf(erica_image_series.id.to_s, @rails_image_storage_root + erica_parent_visit.required_series_image_storage_path(erica_required_series_name))
      end
    end
    def update_image(goodimage_image, erica_image, erica_parent_image_series)
      erica_image.image_series_id = erica_parent_image_series.id
    end
    def copy_image_file(goodimage_image, erica_image)
      begin
        FileUtils.cp(@goodimage_image_storage_root + goodimage_image.file_path, erica_image.absolute_image_storage_path, :preserve => true)
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
        return migration_mapping.target
      elsif(erica_resource.nil?)
        erica_resource = erica_resource_class.new
      end

      # update values
      yield(goodimage_resource, erica_resource)

      Rails.logger.debug "Created/Updated ERICA resource: #{erica_resource.inspect}"

      unless(erica_resource.save)
        Rails.logger.fatal "Failed to save ERICA resource, aborting"
        Rails.logger.fatal erica_resource.errors.inspect
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
    def goodimage_resource_from_mapping(type, erica_id)
      goodimage_resource = nil
      migration_mapping = Migration::Mapping.first(:type => type, :target_id => erica_id)
      if(migration_mapping)
        goodimage_resource_id = migration_mapping.source_id


        goodimage_resource = migration_mapping.source
        
        return goodimage_resource
      end

      return nil
    end
  end
end
