class PatientReadExportWorker
  include Sidekiq::Worker

  def case_list
    @case_list ||= StringIO.new.tap do |str|
      str.puts('patient,images,type')
    end
  end

  def perform(job_id, export_folder_name, patient_ids)
    job = BackgroundJob.find(job_id)

    export_path = ERICA.image_export_path.join(export_folder_name)
    if export_path.exist? && !export_path.directory?
      job.fail("The export target folder #{export_path} exists, but is not a folder.")
      return
    end

    begin
      patients = Patient.find(patient_ids)
    rescue ActiveRecord::RecordNotFound => e
      job.fail("Not all selected patients were found: #{e.message}")
      return
    end

    patients.each_with_index do |patient, index|
      export_log = export_patient(patient, export_path)

      patient.export_history = Array(patient.export_history).push(export_log)
      patient.save

      job.set_progress(index + 1, patients.size)
    end

    job.finish_successfully('Case List' => case_list.string)
  end

  def export_patient(patient, export_path)
    patient_export_path = export_path.join(patient.name)
    patient_export_path.rmtree if patient_export_path.exist?
    patient_export_path.mkpath

    visits_log = patient.visits.map do |visit|
      export_visit(visit, patient_export_path)
    end

    {
      exported_at: Time.now.to_i,
      patient_id: patient.id,
      patient_name: patient.name,
      export_path: patient_export_path.to_s,
      visits: visits_log
    }
  end

  def export_visit(visit, export_path)
    visit_export_path = export_path.join(visit.visit_number.to_s)
    visit_export_path.mkdir

    case_list.puts("#{visit.patient.name},#{visit.visit_number},#{visit.visit_type}")

    required_series_log = visit.required_series.map do |required_series|
      export_required_series(required_series, visit_export_path)
    end

    {
      visit_id: visit.id,
      visit_number: visit.visit_number,
      export_path: visit_export_path.to_s,
      required_series: required_series_log.compact
    }
  end

  def export_required_series(required_series, export_path)
    return if required_series.assigned_image_series.nil?

    required_series_export_path = export_path.join(required_series.name)
    assigned_image_series_path = ERICA.image_storage_path.join(required_series.assigned_image_series.image_storage_path)
    symlink_target = assigned_image_series_path.relative_path_from(export_path)
    required_series_export_path.make_symlink(symlink_target)

    {
      required_series_name: required_series.name,
      assigned_image_series: required_series.assigned_image_series.id,
      export_path: required_series_export_path.to_s,
      sop_instance_uid: get_sop_instance_uid(required_series)
    }
  end

  def get_sop_instance_uid(required_series)
    sample_image = required_series.assigned_image_series.sample_image
    return nil if sample_image.nil?
    _, dicom_metadata = sample_image.dicom_metadata
    dicom_metadata['0008,0018'].andand[:value]
  end
end
