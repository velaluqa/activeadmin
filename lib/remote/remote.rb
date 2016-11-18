require 'open-uri'

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
    unless localhost?
      bash_command = "bash --login -c #{command.to_s.inspect}"
      command = "ssh #{host} -t #{bash_command.inspect}"
    end
    system(command.to_s)
  end

  def exec_or_die(command)
    unless localhost?
      bash_command = "bash --login -c #{command.to_s.inspect}"
      command = "ssh #{host} -t #{bash_command.inspect}"
    end
    system_or_die(command.to_s)
  end

  def file_exists?(path)
    exec("test -f #{path.shellescape}")
  end

  def mkdir_p(target)
    exec_or_die("mkdir -p #{target.shellescape}")
  end

  def rsync_to(source, target)
    target = "#{host}:#{target}" unless localhost?
    system_or_die("rsync -avz #{source.shellescape} #{target.shellescape}")
  end

  private

  def localhost?
    host =~ /^localhost|127\.0\.0\.1$/
  end

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
    paths_url = File.join(url, '/erica_remote/paths.json')
    data = URI.parse(paths_url).read
    JSON.parse(data)
  end
end
