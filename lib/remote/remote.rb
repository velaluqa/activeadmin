class Remote
  attr_reader :url, :host, :study_ids
  attr_reader :root, :data_dir, :form_config_dir, :session_config_dir,
              :study_config_dir, :image_storage_dir

  def initialize(options = {})
    @url       = options.fetch(:url)
    @host      = options.fetch(:host)
    @study_ids = options.fetch(:study_ids)
    retrieve_paths
  end

  def working_dir
    root.join('tmp', 'remote_sync')
  end

  def exec(command)
    if host !~ /^localhost|127\.0\.0\.1$/
      bash_command = "bash --login -c #{command.to_s.inspect}"
      system("ssh #{host} #{bash_command.inspect}")
    else
      system(command.to_s)
    end
  end

  def mkdir_p(target)
    exec("mkdir -p #{Shellwords.escape(target.to_s)}")
  end

  def rsync_to(source, target)
    if host !~ /^localhost|127\.0\.0\.1$/
      puts("rsync -avz #{Shellwords.escape(source.to_s)} #{host}:#{Shellwords.escape(target.to_s)}")
      system("rsync -avz #{Shellwords.escape(source.to_s)} #{host}:#{Shellwords.escape(target.to_s)}")
    else
      puts("rsync -avz #{Shellwords.escape(source.to_s)} #{Shellwords.escape(target.to_s)}")
      system("rsync -avz #{Shellwords.escape(source.to_s)} #{Shellwords.escape(target.to_s)}")
    end
  end

  private

  def retrieve_paths
    paths               = fetch_paths
    @root               = Pathname.new(paths['root'])
    @data_dir           = Pathname.new(paths['data_directory'])
    @form_config_dir    = Pathname.new(paths['form_config_directory'])
    @session_config_dir = Pathname.new(paths['session_config_directory'])
    @study_config_dir   = Pathname.new(paths['study_config_directory'])
    @image_storage_dir  = Pathname.new(paths['image_storage_directory'])
  end

  def fetch_paths
    uri = URI.join(url, '/erica_remote/paths.json')
    response = Net::HTTP.get_response(uri)
    case response
    when Net::HTTPSuccess then JSON.parse(response.body)
    else
      fail "Failed to retrieve path information ERICA remote at #{uri}: #{response.message}"
    end
  end
end
