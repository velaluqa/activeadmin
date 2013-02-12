class GitConfigRepository
  def initialize
    begin
      @repo = Rugged::Repository.new(Rails.application.config.data_directory)
    rescue Rugged::OSError, Rugged::RepositoryError
      @repo = Rugged::Repository.init_at(Rails.application.config.data_directory, false)
    end    
  end

  def current_version
    @repo.head.resolve.target
  end

  def update_config_file(path, new_file, author, commit_message)
    FileUtils.cp(new_file, @repo.workdir+'/'+path)
    
    index = @repo.index
    index.add(path)
    index.write

    tree = index.write_tree
    
    author_hash = {:email => author.id.to_s, :name => author.username, :time => Time.now}

    options = {}
    options[:author] = author_hash
    options[:committer] = author_hash
    options[:message] = commit_message
    options[:update_ref] = 'HEAD'
    options[:parents] = @repo.empty? ? [] : [@repo.head.target].compact
    options[:tree] = tree

    Rugged::Commit.create(@repo, options)
  end

  def yaml_at_version(path, version = nil)
    version = current_version if version.nil?

    file_blob = file_at_version(path, version)
    return nil if file_blob.nil?

    return YAML.load(file_blob.text)
  end
  def data_at_version(path, version = nil)
    version = current_version if version.nil?

    file_blob = file_at_version(path, version)
    return nil if file_blob.nil?

    return file_blob.content
  end

  protected

  def file_at_version(path, version)
    begin
      return nil unless @repo.exists?(version)      
    rescue Rugged::InvalidError => e
      return nil
    end

    commit = @repo.lookup(version)
    return nil unless commit.type == :commit

    file_blob = access_tree_by_path(commit.tree, path)
    return nil if (file_blob.nil? or file_blob.type != :blob)

    return file_blob
  end
  
  def access_tree_by_path(tree, path)
    return tree if (path.nil? or tree.nil?)

    path_components = path.split('/', 2)

    target_oid = tree[path_components[0]][:oid]
    return nil if target_oid.nil?
    return nil unless @repo.exists?(target_oid)

    target = @repo.lookup(target_oid)
    
    return access_tree_by_path(target, path_components[1])
  end
end
