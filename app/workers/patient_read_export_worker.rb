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
      patient_export_path = Pathname.new(export_root_path.to_s + '/' + patient.name)
      patient_export_path.rmtree if patient_export_path.exist?
      patient_export_path.mkpath
      
      patient.visits.each do |visit|
        next if visit.visit_number.blank?

        visit_export_path = Pathname.new(patient_export_path.to_s + '/' + visit.visit_number.to_s)
        visit_export_path.mkdir

        visit.required_series_objects.each do |required_series|
          next if required_series.assigned_image_series.nil?

          required_series_export_path = Pathname.new(visit_export_path.to_s + '/' + required_series.name)
          assigned_image_series_path = Pathname.new(required_series.assigned_image_series.absolute_image_storage_path)          

          required_series_export_path.make_symlink(assigned_image_series_path.relative_path_from(visit_export_path))
        end

        case_list << {:patient => patient.name, :images => visit.visit_number, :case_type => visit.visit_type}
      end

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
