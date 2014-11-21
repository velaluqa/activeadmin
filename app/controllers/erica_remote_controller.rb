# coding: utf-8
class EricaRemoteController < ApplicationController
  before_filter :skip_trackable # do not track requests to the WADO API as logins/logouts, because every single request would be counted as one login

  # Force load models, so YAML::load can find them... *facepalm*
  Study
  Center
  Patient
  Visit
  ImageSeries
  Image
  VisitData
  PatientData
  ImageSeriesData

  def push
    signature = Base64.strict_decode64(request.headers['X-ERICA-Signature'])
    timestamp = request.headers['X-ERICA-Timestamp']
    records_yaml = gunzip(request.body)

    if(!verify_signature(signature, timestamp, records_yaml))
      render nothing: true, status: :unauthorized
      return
    end

    records = YAML::load(records_yaml)
    puts "Got #{records[:users].count} + #{records[:active_record].count} + #{records[:mongoid].count} records"

    PaperTrail.enabled = false
    Mongoid::History.disable do
      study = records[:study]
      ids = {centers: study.center_ids,
             patients: study.patient_ids,
             visits: study.visit_ids,
             image_series: study.image_series_ids,
             images: study.image_series.map{|is| is.image_ids}.flatten,
            }

      if(Study.exists?(study.id))
        # we aways recreate all MongoDB entries, to be sure to keep them in sync

        study.image_series.each do |image_series|
          image_series.image_series_data.destroy if image_series.image_series_data
        end
        study.visits.each do |visit|
          visit.visit_data.destroy if visit.visit_data
        end
        study.patients.each do |patient|
          patient.patient_data.destroy if patient.patient_data
        end
      end

      records[:users].each do |record|
        record.locked_at = Time.now

        if(record.class.exists?(record.id))
          attributes = record.attributes
          attributes.delete(:id)

          existing_record = record.class.find(record.id)
          existing_record.assign_attributes(attributes, without_protection: true)
          existing_record.save!(validate: false)
        else
          record.instance_variable_set("@new_record", true)
          record.save!(validate: false)
        end
      end

      records[:mongoid].each do |record|
        record.upsert
      end

      records[:active_record].each do |record|
        case record
        when Center then ids[:centers].delete(record.id)
        when Patient then ids[:patients].delete(record.id)
        when Visit then ids[:visits].delete(record.id)
        when ImageSeries then ids[:image_series].delete(record.id)
        when Image then ids[:images].delete(record.id)
        end

        if(record.class.exists?(record.id))
          attributes = record.attributes
          attributes.delete(:id)

          existing_record = record.class.find(record.id)
          existing_record.assign_attributes(attributes, without_protection: true)
          existing_record.save
        else
          record.instance_variable_set("@new_record", true)
          record.save
        end
      end

      Image.destroy(ids[:images])
      ImageSeries.destroy(ids[:image_series])
      Visit.destroy(ids[:visits])
      Patient.destroy(ids[:patients])
      Center.destroy(ids[:centers])
    end
    PaperTrail.enabled = true

    render nothing: true
  end

  def paths
    unless(Study.exists?(params[:study_id]))
      render nothing: true, status: :not_found
      return
    end

    study = Study.find(params[:study_id])

    configs_path = Rails.root.join(Rails.application.config.data_directory).to_s
    image_storage_path = Rails.root.join(study.absolute_image_storage_path).to_s

    render json: {configs: configs_path, images: image_storage_path}
  end

  protected

  def verify_signature(signature, timestamp, data)
    # we check wether the timestamp is within 1 hour (60*60 seconds) of now, in either direction
    # this effectively gives you a one hour window for replay attacks, given that the clocks are synched
    return false if (Time.now.to_i - timestamp.to_i).abs > 60*60

    key_path = Rails.root.join(Rails.application.config.erica_remote_verification_key)
    key = OpenSSL::PKey::RSA.new(File.read(key_path))

    return key.verify(OpenSSL::Digest::SHA512.new, signature, data + timestamp)
  end

  def gunzip(body_io)
    gzipper = Zlib::GzipReader.new(body_io)
    return gzipper.read
  end

  def skip_trackable
    request.env['devise.skip_trackable'] = true
  end
end
