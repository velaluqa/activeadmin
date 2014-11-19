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
