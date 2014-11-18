require 'zip'

class DownloadImagesWorker
  include Sidekiq::Worker

  def perform(background_job_id, resource_type, resource_id)
    job = BackgroundJob.find(job_id)

    resource = case resource_type
               when 'Patient'
                 Patient.find(resource_id)
               when 'Visit'
                 Visti.find(visit_id)
               else
                 job.fail('Invalid resource type: ' + resource_type.to_s)
                 return
               end

    # TODO: create proper output directory structure
    image_storage_path = Rails.root.join(Rails.application.config.image_storage_root, resource.image_storage_path, '**/*').to_s
    images = Dir.glob(image_storage_path)

    output_path = Pathname.new(Dir.tmpfile).join('images_' + job_id.to_s + '.zip').to_s

    Zip::File.open(output_path, Zip::File::CREATE) do |zipfile|
      images.each do |image|
        # TODO: add images
      end
    end
  end
end
