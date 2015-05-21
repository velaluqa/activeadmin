class Remote
  attr_reader :name, :url, :host, :study_ids
  attr_reader :root, :data_dir, :form_config_dir, :session_config_dir,
              :study_config_dir, :image_storage_dir

  def initialize(arg = {})
    case arg
    when Remote then load_remote(arg)
    when Hash   then load_hash(arg)
    else fail 'Given remote argument is not allowed.'
    end
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

  def file_exists?(path)
    exec("test -f #{path.shellescape}")
  end

  def mkdir_p(target)
    exec("mkdir -p #{Shellwords.escape(target.to_s)}")
  end

  def rsync_to(source, target)
    if host !~ /^localhost|127\.0\.0\.1$/
      system("rsync -avz #{Shellwords.escape(source.to_s)} #{host}:#{Shellwords.escape(target.to_s)}")
    else
      system("rsync -avz #{Shellwords.escape(source.to_s)} #{Shellwords.escape(target.to_s)}")
    end
  end

  private

  def load_remote(remote)
    @name      = remote.name
    @url       = remote.url
    @host      = remote.host
    @study_ids = remote.study_ids
  end

  def load_hash(hash)
    hash.symbolize_keys!
    @name      = hash.fetch(:name)
    @url       = hash.fetch(:url)
    @host      = hash.fetch(:host)
    @study_ids = hash.fetch(:study_ids).map(&:to_s)
  end

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
