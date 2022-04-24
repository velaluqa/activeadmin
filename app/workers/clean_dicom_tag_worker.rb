class CleanDicomTagWorker
  include Sidekiq::Worker

  def backup_file_path(image)
    date = Date.today.strftime('%Y-%m-%d')

    count = 0
    FileUtils.mkdir_p(ERICA.backup_path.join("images", date).to_s)

    backup_file_path = ERICA.backup_path.join("images", date, "#{image.id}.#{count}").to_s
    while File.exists?(backup_file_path)
      count += 1
      backup_file_path = ERICA.backup_path.join("images", date, "#{image.id}.#{count}").to_s
    end
    backup_file_path
  end

  def clean_tag_for_image(image, tag)
    image_path = ERICA.image_storage_path.join(image.image_storage_path)

    FileUtils.cp(image_path, backup_file_path(image))

    dicom = DICOM::DObject.read(image_path.to_s)

    if dicom.exists?(tag)
      dicom[tag].value = ""
    else
      dicom.add_element(tag, "")
    end

    original_attributes_seq = dicom[DICOM::Tag.OriginalAttributesSequence]
    original_attributes_seq ||= DICOM::Sequence.new(DICOM::Tag.OriginalAttributesSequence, parent: dicom)
    original_attributes = original_attributes_seq.add_item

    original_attributes.add_element(DICOM::Tag.AttributeModificationDateTime, DateTime.now.utc.strftime("%Y%m%d%H%M%S.%6N"))
    original_attributes.add_element(DICOM::Tag.ModifyingSystem, "Pharmtrace ERICA SaaS #{ERICA.version}")
    original_attributes.add_element(DICOM::Tag.ReasonForTheAttributeModification, "COERCE")

    modified_attributes_seq = DICOM::Sequence.new(DICOM::Tag.ModifiedAttributesSequence, parent: original_attributes)
    modified_attributes = modified_attributes_seq.add_item
    modified_attributes.add_element(tag, "")

    dicom.write(image_path.to_s)

    image.sha256sum = Digest::SHA256.hexdigest(File.read(image_path.to_s))
    image.save
  end

  def perform(job_id, scope_classname, scope_id, tag)
    job = BackgroundJob.find(job_id)

    ::PaperTrail.request.whodunnit = job.user_id

    object = find_scope_object(scope_classname, scope_id)
    image_count = object.images.count

    object.images.each_with_index do |image, i|
      clean_tag_for_image(image, tag)

      job.set_progress(i, image_count)
    end

    job.finish_successfully()
  ensure
    ::PaperTrail.request.whodunnit = nil
  end

  private

  def find_scope_object(scope_classname, scope_id)
    klass =
      case scope_classname
      when "ImageSeries" then ImageSeries
      when "Study" then Study
      else raise "Unknown scope `#{scope}`"
      end
    klass.find(scope_id)
  end
end
