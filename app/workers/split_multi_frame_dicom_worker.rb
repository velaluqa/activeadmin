require 'sidekiq_background_job'

class SplitMultiFrameDicomWorker
  include SidekiqBackgroundJob

  # Here we expect that the file already was decompressed and
  # anonymized.
  def perform_job(image_id)
    image = Image.find(image_id)
    source_path = image.absolute_image_storage_path

    return succeed! unless DICOM::FileUtils.multi_frame?(source_path)

    dicom = DICOM::DObject.read(source_path)
    frame_count = dicom.number_of_frames.value.to_i
    set_progress_total!(frame_count)

    target_dir = Dir.mktmpdir("split-multi-frame", "/tmp")
    target_path = File.join(target_dir, "frame")

    DICOM::FileUtils.dcuncat(
      source_path,
      target_path,
      unenhance: true,
      instancenumber: true,
      noprivateattr: true,
      removeprivate: true,
      framesper: 1
    )

    ordered_frames = Dir["#{target_dir}/*"].sort_by { |v| File.basename(v)[/\d+/].to_i }

    ordered_frames.each do |single_frame_path|
      single_frame_image = Image.create!(
        image_series_id: image.image_series_id,
        mimetype: "application/dicom",
        sha256sum: Image.sha256sum(single_frame_path)
      )
      ::FileUtils.cp(
        single_frame_path,
        single_frame_image.absolute_image_storage_path
      )

      increment_progress!
    end

    image.destroy!

    succeed!
  end
end
