# coding: utf-8
class EricaRemoteController < ApplicationController
  before_filter :skip_trackable # do not track requests to the ERICA Remote API as logins/logouts, because every single request would be counted as one login

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

      unless Study.exists?(study.id)
        study.instance_variable_set('@new_record', true)
        study.save!(validate: false)
      end

      ids = {
        centers: study.center_ids,
        patients: study.patient_ids,
        visits: study.visit_ids,
        image_series: study.image_series_ids,
        images: study.image_series.map(&:image_ids).flatten
      }

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

      records[:users].each do |record|
        record.locked_at = Time.now

        if record.class.exists?(record.id)
          attributes = record.attributes
          attributes.delete(:id)

          existing_record = record.class.find(record.id)
          existing_record.assign_attributes(
            attributes,
            without_protection: true
          )
          existing_record.save!(validate: false)
        else
          record.instance_variable_set('@new_record', true)
          record.save!(validate: false)
        end
      end

      records[:mongoid].each(&:upsert)

      records[:active_record].each do |record|
        case record
        when Center then ids[:centers].delete(record.id)
        when Patient then ids[:patients].delete(record.id)
        when Visit then ids[:visits].delete(record.id)
        when ImageSeries then ids[:image_series].delete(record.id)
        when Image then ids[:images].delete(record.id)
        end

        if record.class.exists?(record.id)
          attributes = record.attributes
          attributes.delete(:id)

          existing_record = record.class.find(record.id)
          existing_record.assign_attributes(
            attributes,
            without_protection: true
          )
          existing_record.save
        else
          record.instance_variable_set('@new_record', true)
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
    # TODO: Refactor this information into an ERICA object.
    data_directory            = (Rails.root + Pathname.new(Rails.application.config.data_directory)).to_s
    form_config_directory     = (Rails.root + Pathname.new(Rails.application.config.form_configs_directory)).to_s
    session_config_directory  = (Rails.root + Pathname.new(Rails.application.config.session_configs_directory)).to_s
    study_config_directory    = (Rails.root + Pathname.new(Rails.application.config.study_configs_directory)).to_s
    image_storage_directory   = (Rails.root + Pathname.new(Rails.application.config.image_storage_root)).to_s

    render json: {
      root: Rails.root.to_s,
      data_directory: data_directory,
      form_config_directory: form_config_directory,
      session_config_directory: session_config_directory,
      study_config_directory: study_config_directory,
      image_storage_directory: image_storage_directory
    }
  end

  protected

  def verify_signature(signature, timestamp, data)
    # We check wether the timestamp is within 1 hour (60*60 seconds)
    # of now, in either direction this effectively gives you a one
    # hour window for replay attacks, given that the clocks are
    # synched.
    return false if (Time.now.to_i - timestamp.to_i).abs > 60 * 60

    key_path = Rails.root.join(Rails.application.config.erica_remote_verification_key)
    key = OpenSSL::PKey::RSA.new(File.read(key_path))

    key.verify(OpenSSL::Digest::SHA512.new, signature, data + timestamp)
  end

  def gunzip(body_io)
    Zlib::GzipReader.new(body_io).read
  end

  def skip_trackable
    request.env['devise.skip_trackable'] = true
  end
end
