class PatientReadExportWorker
  include Sidekiq::Worker

  def perform(job_id, export_folder, patient_ids)
    job = BackgroundJob.find(job_id)

    case_list = []

    export_root_path = Pathname.new(Rails.application.config.image_export_root + '/' + export_folder)
    if(export_root_path.exist? and not export_root_path.directory?)
      job.fail('The export target folder '+export_root_path.to_s+' exists, but isn\'t a folder.')
      return
    end

    begin
      patients = Patient.find(patient_ids)
    rescue ActiveRecord::RecordNotFound => e
      job.fail('Not all selected patients were found: '+e.message)
      return
    end

    patients.each_with_index do |patient, index|
      export_log_entry = {
        exported_at: Time.now.to_i,
        patient_id: patient.id,
        patient_name: patient.name,
        visits: [],
      }

      patient_export_path = Pathname.new(export_root_path.to_s + '/' + patient.name)
      patient_export_path.rmtree if patient_export_path.exist?
      patient_export_path.mkpath
      export_log_entry[:export_path] = patient_export_path.to_s

      patient.visits.each do |visit|
        next if visit.visit_number.blank?

        visit_log_entry = {
          visit_id: visit.id,
          visit_number: visit.visit_number,
          required_series: [],
        }

        visit_export_path = Pathname.new(patient_export_path.to_s + '/' + visit.visit_number.to_s)
        visit_export_path.mkdir
        visit_log_entry[:export_path] = visit_export_path.to_s

        visit.required_series_objects.each do |required_series|
          next if required_series.assigned_image_series.nil?

          required_series_log_entry = {
            required_series_name: required_series.name,
            assigned_image_series: required_series.assigned_image_series.id,
          }

          required_series_export_path = Pathname.new(visit_export_path.to_s + '/' + required_series.name)
          assigned_image_series_path = Pathname.new(required_series.assigned_image_series.absolute_image_storage_path)
          required_series_log_entry[:export_path] = required_series_export_path.to_s
          sample_image = required_series.assigned_image_series.sample_image
          unless sample_image.nil?
            _, dicom_metadata = sample_image.dicom_metadata
            sop_instance_uid = dicom_metadata['0008,0018']

            required_series_log_entry[:sop_instance_uid] = sop_instance_uid[:value] unless sop_instance_uid.nil?
          end

          required_series_export_path.make_symlink(assigned_image_series_path.relative_path_from(visit_export_path))

          visit_log_entry[:required_series] << required_series_log_entry
        end

        case_list << {:patient => patient.name, :images => visit.visit_number, :case_type => visit.visit_type}

        export_log_entry[:visits] << visit_log_entry
      end

      if patient.export_history.is_a?(Array)
        patient.export_history << export_log_entry
      else
        patient.export_history = [export_log_entry]
      end
      patient.save

      job.set_progress(index+1, patients.size)
    end

    csv_options = {
      :col_sep => ',',
      :row_sep => :auto,
      :quote_char => '"',
      :headers => true,
      :converters => [:all, :date],
      :unconverted_fields => true,
    }
    case_list_csv = CSV.generate(csv_options) do |csv|
      csv << ['patient', 'images', 'type']
      case_list.each do |c|
        csv << [c[:patient], c[:images], c[:case_type]]
      end
    end

    job.finish_successfully({'Case List' => case_list_csv})
  end
end
