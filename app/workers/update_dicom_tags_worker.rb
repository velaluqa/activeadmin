require 'sidekiq_background_job'

class UpdateDicomTagsWorker
  include SidekiqBackgroundJob

  RESOURCES = %w[ImageSeries Patient Center]

  def perform_job(resource_type, resource_id)
    fail "Denied resource type: #{resource_type}" if wrong_type?(resource_type)

    ensure_backup_dir!

    images =
      resource_type.constantize.find(resource_id).images

    set_progress_total!(images.count)

    images.find_each do |image|
      backup!(image)

      unless write_new_patient_name!(image)
        fail "Unable to modify dicom file"
      end

      increment_progress!
    end

    delete_backup_dir!
    succeed!
  end

  private

  def backup_dir
    @backup_dir ||= ERICA.backup_path.join("background_job_images", job_id.to_s).to_s
  end

  def ensure_backup_dir!
    FileUtils.mkdir_p(backup_dir)
  end

  def delete_backup_dir!
    FileUtils.rm_rf(backup_dir)
  end

  def wrong_type?(resource_type)
    !RESOURCES.include?(resource_type)
  end

  def backup!(image)
    image_file = image.absolute_image_storage_path
    backup_file = File.join(backup_dir, image.id.to_s)

    FileUtils.cp(image_file, backup_file)
  end

  def restore!(image)
    image_file = image.absolute_image_storage_path
    backup_file = File.join(backup_dir, image.id.to_s)

    FileUtils.cp_f(backup_file, image_file)
  end

  def write_new_patient_name!(image)
    patient_name = image.image_series.patient.name
    return true if image.dicom.patients_name.value == patient_name

    dicom = image.dicom
    dicom.patients_name = patient_name
    dicom.write(image.absolute_image_storage_path)

    image.update_checksum!

  rescue => e
    restore!(image)

    raise e
  end
end
