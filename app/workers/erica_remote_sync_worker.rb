class ERICARemoteSyncWorker
  include Sidekiq::Worker

  def system_or_die(command)
    unless(system(command))
      raise 'Failed to execute shell command: "' + command + '"'
    end
  end
  def rsync_or_die(source, destination, use_ssh = false)
    sync_command = "rsync -av #{use_ssh ? '-essh' : ''} '#{source}' '#{destination}'"

    puts 'EXECUTING: ' + sync_command
    system_or_die(sync_command)
  end

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

    timestamp = Time.now.to_i.to_s

    signature = key.sign(OpenSSL::Digest::SHA512.new, data + timestamp)
    pp OpenSSL.errors

    return [signature, timestamp]
  end

  def compile_records(study)
    records = {study: study, users: [], active_record: [], mongoid: []}

    records[:users] += User.all

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

    signature, timestamp = sign_data(yaml)

    gzipped = gzip(yaml)

    return [signature, timestamp, gzipped]
  end

  def push_records(uri, data, signature, timestamp)
    Net::HTTP.start(uri.host, uri.port) do |http|
      push_request = Net::HTTP::Post.new(uri.path, {'X-ERICA-Signature' => Base64.strict_encode64(signature), 'X-ERICA-Timestamp' => timestamp, 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/yaml'})
      push_request.body = data

      response = http.request(push_request)

      unless response.code.to_i == 200
        raise "Failed to push records to ERICA Remote at #{uri.to_s}: #{response.message}"
      end
    end
  end

  def retrieve_paths(uri, study_id)
    query = URI.decode_www_form(uri.query || '')
    query << ['study_id', study_id.to_s]
    uri.query = URI.encode_www_form(query)

    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      JSON::parse(response.body)
    else
      raise "Failed to retrieve path information for study #{study_id} from ERICA Remote at #{uri.to_s}: #{response.message}"
    end
  end
  
  def perform(job_id, study_id, erica_remote_url, rsync_host = nil)
    job = BackgroundJob.find(job_id)

    erica_remote_uri = URI::join(erica_remote_url, 'erica_remote/push')
    erica_remote_paths_uri = URI::join(erica_remote_url, 'erica_remote/paths')

    study = Study.find(study_id)

    records_signature, signature_timestamp, gzipped_records = sign_and_gzip_records(compile_records(study))
    push_records(erica_remote_uri, gzipped_records, records_signature, signature_timestamp)

    config_paths = [
      Rails.root.join(Rails.application.config.data_directory, '.git').to_s.chomp('/'),
      Rails.root.join(Rails.application.config.study_configs_directory).to_s.chomp('/'),
      Rails.root.join(Rails.application.config.form_configs_directory).to_s.chomp('/'),
      Rails.root.join(Rails.application.config.session_configs_directory).to_s.chomp('/'),
    ]
    local_paths = {
      'configs' => config_paths.join('\' \''),
      'images' => Rails.root.join(study.absolute_image_storage_path).to_s,
    }

    remote_paths = retrieve_paths(erica_remote_paths_uri, study_id)
    unless(rsync_host.blank?)
      remote_paths['configs'] = rsync_host + ':' + remote_paths['configs']
      remote_paths['images'] = rsync_host + ':' + remote_paths['images']
    end

    local_paths['images'] += '/' unless local_paths['images'].end_with?('/')

    remote_paths['configs'] += '/' unless remote_paths['configs'].end_with?('/')
    remote_paths['images'] = remote_paths['images'].chomp('/')

    rsync_or_die(local_paths['configs'], remote_paths['configs'], !(rsync_host.blank?))
    rsync_or_die(local_paths['images'], remote_paths['images'], !(rsync_host.blank?))

    job.finish_successfully({})
  end
end
