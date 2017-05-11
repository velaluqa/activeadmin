require "#{Rails.root}/app/helpers/active_admin/images_helper"

include ActiveAdmin::ImagesHelper

namespace :erica do
  desc 'Compile a list of all image series uploaded since the given date, including information about "wrong" uploads'
  task :image_series_report, %i[year month day] => [:environment] do |_t, args|
    if args[:year].blank? || args[:month].blank? || args[:day].blank?
      $stderr.puts 'No date given, aborting.'
      next
    end

    start_time = DateTime.new(args[:year].to_i, args[:month].to_i, args[:day].to_i)
    $stderr.puts "Compiling report of all image series uploaded since #{start_time}..."

    image_series = ImageSeries.where('created_at >= ?', start_time)
    $stderr.puts "Found #{image_series.count} created since #{start_time}..."

    puts '"Study Number","ERICA Patient Name","DICOM Patient Name","ERICA DoI","DICOM DoI","ERICA Series Name","Images Count","Created at","URL","Patient Mismatch"'

    count = 0
    failed_count = 0
    image_series.find_each do |is|
      count += 1

      study_name = is.study.name
      erica_subject_id = (is.patient.nil? ? nil : is.patient.subject_id)
      erica_patient_name = (is.patient.nil? ? nil : is.patient.name)
      erica_imaging_date = is.imaging_date.to_s
      series_description = is.name
      images_count = is.images.count

      sample_image = is.sample_image
      dicom_metadata_header, dicom_metadata = (sample_image.nil? ? [{}, {}] : sample_image.dicom_metadata)

      dicom_patient_name = (dicom_metadata['0010,0010'].nil? ? nil : dicom_metadata['0010,0010'][:value])
      dicom_imaging_date = (dicom_metadata['0008,0022'].nil? ? dicom_metadata['0008,0023'] : dicom_metadata['0008,0022'])
      dicom_imaging_date = ActiveAdmin::ImagesHelper.pretty_print_dicom_tag(dicom_imaging_date[:value], dicom_imaging_date[:vr]) unless dicom_imaging_date.nil?

      mismatch = (dicom_patient_name != erica_subject_id)
      failed_count += 1 if mismatch

      puts '"' + study_name + '","' + erica_patient_name + '","' + dicom_patient_name.to_s + '","' + erica_imaging_date.to_s + '","' + dicom_imaging_date.to_s + '","' + series_description + '","' + images_count.to_s + '","' + is.created_at.to_s + '","http://192.168.1.28/admin/image_series/' + is.id.to_s + '",' + (mismatch ? 'Yes' : 'No')

      $stderr.puts "#{count}/#{failed_count}.." if count % 100 == 0
    end

    $stderr.puts "Done, found #{failed_count} offending image series out of #{count} total."
  end
end
