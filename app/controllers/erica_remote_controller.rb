# coding: utf-8

class EricaRemoteController < ApplicationController
  before_filter :skip_trackable # do not track requests to the ERICA Remote API as logins/logouts, because every single request would be counted as one login

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
