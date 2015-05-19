class Remote
  attr_reader :url, :host
  attr_reader :root, :data_dir, :form_config_dir, :session_config_dir,
              :study_config_dir, :image_storage_dir

  def initialize(options = {})
    @url  = options.fetch(:url)
    @host = options.fetch(:host)
    retrieve_paths
  end

  def working_dir
    root.join('tmp', 'remote_sync')
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
