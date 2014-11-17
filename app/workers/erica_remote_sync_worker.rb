class ERICARemoteSyncWorker
  include Sidekiq::Worker

  def gzip(data)
    io = StringIO.new('w')

    gzipper = Zlib::GzipWriter.new(io)
    gzipper.write(data)
    gzipper.close

    return io.string
  end

  def sign_data(data)
    key_path = Rails.root.join(Rails.application.config.erica_remote_signing_key)
    key = OpenSSL::PKey::RSA.new(File.read(key_path))

    signature = key.sign(OpenSSL::Digest::SHA512.new, data)
    pp OpenSSL.errors

    return signature
  end

  def compile_records(study)
    records = {users: [], active_record: [], mongoid: []}

    records[:users] += User.all

    records[:active_record] += [study]
    records[:active_record] += study.centers
    records[:active_record] += study.patients
    records[:active_record] += study.visits
    records[:active_record] += study.image_series
    records[:active_record] += study.image_series.map {|is| is.images}.flatten(1)

    records[:mongoid] += study.patients.reject{|p| p.patient_data.nil?}.map {|p| p.patient_data}
    records[:mongoid] += study.visits.reject{|v| v.visit_data.nil?}.map {|v| v.visit_data}
    records[:mongoid] += study.image_series.reject{|is| is.image_series_data.nil?}.map {|is| is.image_series_data}

    return records
  end
  def sign_and_gzip_records(records)
    yaml = records.to_yaml

    signature = sign_data(yaml)

    gzipped = gzip(yaml)

    return [signature, gzipped]
  end

  def push_records(uri, data, signature)
    Net::HTTP.start(uri.host, uri.port) do |http|
      push_request = Net::HTTP::Post.new(uri.path, {'X-ERICA-Signature' => Base64.strict_encode64(signature), 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/yaml'})
      push_request.body = data
      
      response = http.request(push_request)
      # TODO: error handling     
      pp response
    end
  end
  
  def perform(job_id, study_id, erica_remote_url)
    job = BackgroundJob.find(job_id)

    erica_remote_uri = URI::join(erica_remote_url, 'erica_remote/push')
    
    study = Study.find(study_id)

    records_signature, gzipped_records = sign_and_gzip_records(compile_records(study))
    push_records(erica_remote_uri, gzipped_records, records_signature)

    job.finish_successfully({})
  end
end
