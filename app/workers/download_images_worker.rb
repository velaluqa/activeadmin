require 'tempfile'
require 'sidekiq_background_job'

require 'zip'
require 'zip/filesystem'

class DownloadImagesWorker
  include SidekiqBackgroundJob
  
  # output directory structure:
  # patient.name
  # - patient.visits.each do
  #   visit.number
  #   - visit.required_series.each do
  #     required_series.name
  #     - required_series.assigned_image_series.images.each do
  #       image

  def add_image(zip, image)
    zip.file.open(image.id.to_s, 'w') do |outfile|
      outfile.write(
        File.open(Rails.root.join(image.absolute_image_storage_path).to_s, 'r', &:read)
      )
    end

    @images_done += 1
  end

  def add_image_series(zip, image_series, create_folder = true)
    if create_folder
      image_series_dir = image_series.id.to_s

      zip.dir.mkdir(image_series_dir)
      zip.dir.chdir(image_series_dir)
    end

    image_series.images.each do |image|
      add_image(zip, image)
    end

    @job.set_progress(@images_done, @images_count)

    zip.dir.chdir('..') if create_folder
  end

  def add_visit(zip, visit)
    visit_dir = visit.visit_number.to_s

    zip.dir.mkdir(visit_dir)
    zip.dir.chdir(visit_dir)

    visit.required_series_objects.each do |required_series|
      next if required_series.assigned_image_series.nil?

      required_series_dir = required_series.name

      zip.dir.mkdir(required_series_dir)
      zip.dir.chdir(required_series_dir)

      add_image_series(zip, required_series.assigned_image_series, false)

      zip.dir.chdir('..')
    end

    visit.image_series.select { |is| is.assigned_required_series.empty? }.each do |image_series|
      add_image_series(zip, image_series, true)
    end

    zip.dir.chdir('..')
  end

  def add_patient(zip, patient)
    patient_dir = patient.name

    zip.dir.mkdir(patient_dir)
    zip.dir.chdir(patient_dir)

    patient.visits.each do |visit|
      add_visit(zip, visit)
    end

    unassigned_image_series_dir = '__unassigned'

    zip.dir.mkdir(unassigned_image_series_dir)
    zip.dir.chdir(unassigned_image_series_dir)

    patient.image_series.select { |is| is.visit.nil? }.each do |image_series|
      add_image_series(zip, image_series, true)
    end

    zip.dir.chdir('..')

    zip.dir.chdir('..')
  end

  def perform(job_id, resource_type, resource_id)
    @job = BackgroundJob.find(job_id)

    resource = case resource_type
               when 'Patient'
                 Patient.find(resource_id)
               when 'Visit'
                 Visit.find(resource_id)
               else
                 @job.fail('Invalid resource type: ' + resource_type.to_s)
                 return
               end

    @images_count = resource.images.count * 1.5
    @images_done = 0

    # TODO: create proper output directory structure
    image_storage_path = Rails.root.join(Rails.application.config.image_storage_root, resource.image_storage_path, '**/*').to_s
    images = Dir.glob(image_storage_path)

    output_dir_path = Pathname.new("/app/tmp").join('erica/download_images_worker')
    FileUtils.mkdir_p(output_dir_path.to_s)
    output_path = output_dir_path.join('images_' + job_id.to_s + '.zip').to_s

    Zip::File.open(output_path, Zip::File::CREATE) do |zipfile|
      case resource
      when Patient
        add_patient(zipfile, resource)
      when Visit
        add_visit(zipfile, resource)
      end

      @keep_updating = true
      Thread.new do
        while @keep_updating
          @images_done += (@images_count.to_f - @images_done.to_f) * 0.1
          @job.set_progress(@images_done, @images_count)
          sleep 1
        end
      end
    end

    @job.finish_successfully('zipfile' => output_path)
  rescue => error
    @job.fail(error.message)
  ensure
    @keep_updating = false
  end
end
