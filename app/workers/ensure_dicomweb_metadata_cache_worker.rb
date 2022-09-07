require 'sidekiq_background_job'

class EnsureDicomwebMetadataCacheWorker
  include Sidekiq::Worker

  sidekiq_options(queue: :critical, retry: 5)

  IMAGE_TAGS = [
    '00080016', # sop class uid
    '00080018', # sop instance uid
    '00080060', # modality
    '00280002', # samples per pixel
    '00280004', # photometric interpretation
    '00280010', # rows
    '00280011', # columns
    '00280030', # pixel spacing
    '00280100', # bits allocated
    '00280101', # bits stored
    '00280102', # high bit
    '00280103', # pixel respresentation
    '00281050', # window center
    '00281051', # window width
    '00281052', # rescale intercept
    '00281053', # rescale slope
    '00200032', # image position (patient)
    '00200037',  # image orientation (patient)
    '0020000D', # study instance uid
    '0020000E' # series instance uid
  ]

  IMAGE_SERIES_TAGS = [
    '00080005', # character set
    '00080054', # retrieve ae title
    '00080056', # instance available
    '00080060', # modality
    '0008103E', # series description
    '00081190', # wado retrieve url
    '0020000E', # series instance uid
    '00200011', # series number
    '00201209', # number of series related instances
  ]

  PATIENT_TAGS = [
    '00080005', # character set
    '00080020', # study date
    '00080030', # study time
    '00080050', # accession number
    '00080054', # retrieve ae title
    '00080056', # instance available
    '00080061', # modality in study
    '00080090', # referring physicians name
    '00081190', # wado retrieve url
    '00100010', # patient name
    '00100020', # patient id
    '00100030', # patient birth date
    '00100040', # patient sex
    '0020000D', # study instance uid
    '00200010', # study id
    '00201206', # unknown
    '00201208', # unknown
  ]

  def cache_patient_metadata(id)
    patient = Patient.find(id)
    json = patient.dicom_metadata(filter_tags: PATIENT_TAGS)

    patient.cache["dicomwebMetadata"] = json

    patient.save
  end

  def cache_image_series_metadata(id)
    image_series = ImageSeries.find(id)
    json = image_series.dicom_metadata(filter_tags: IMAGE_SERIES_TAGS)

    image_series.cache["dicomwebMetadata"] = json

    image_series.save
  end

  def cache_image_metadata(id)
    image = Image.find(id)
    json = image.dicom_metadata_json(filter_tags: IMAGE_TAGS)

    image.cache["dicomwebMetadata"] = json

    image.save
  end

  def perform(scope, scope_ids)
    case scope
    when "image"
      puts "Updating images ..."
      progressbar = ProgressBar.create(
        format: '%a |%b>>%i| %p%% %t %e',
        total: scope_ids.length
      )
      scope_ids.each_with_index do |id, i|
        cache_image_metadata(id)
        progressbar.increment
      end

      puts "Updating image series ..."
      image_series_ids = Image.where(id: scope_ids).pluck(:image_series_id).uniq.sort
      progressbar = ProgressBar.create(
        format: '%a |%b>>%i| %p%% %t %e',
        total: image_series_ids.length
      )
      image_series_ids.each_with_index do |id, i|

        cache_image_series_metadata(id)
        progressbar.increment
      end

      puts "Updating image series ..."
      image_series_ids = Image.where(id: scope_ids).pluck(:image_series_id).uniq.sort
      patient_ids = ImageSeries.where(id: image_series_ids).pluck(:patient_id).uniq.sort
      progressbar = ProgressBar.create(
        format: '%a |%b>>%i| %p%% %t %e',
        total: patient_ids.length
      )
      patient_ids.each_with_index do |id, i|
        cache_patient_metadata(id)
        progressbar.increment
      end
    when "image_series" then fail "image series not allowed"
    when "patient" then fail "image series not allowed"
    end
  end
end
