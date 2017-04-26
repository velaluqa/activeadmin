class GitConfigCommit
  extend ActiveModel::Naming

  attr_reader :commit, :oid, :message, :author_id, :author_name, :time

  def initialize(commit)
    @commit = commit
    @oid = commit.oid
    @message = commit.message
    @author_id = commit.author[:email].to_i
    @author_name = commit.author[:name]
    @time = commit.time
  end

  def to_key
    nil
  end
end

class GitConfigRepository
  def initialize
    @repo = Rugged::Repository.new(Rails.application.config.data_directory)
  rescue Rugged::OSError, Rugged::RepositoryError
    @repo = Rugged::Repository.init_at(Rails.application.config.data_directory, false)
  ensure
    if @repo.empty?
      options = {}
      options[:author] = { :email => "erica@pharmtrace.com", :name => 'ERICA', :time => Time.now }
      options[:committer] = { :email => "erica@pharmtrace.com", :name => 'ERICA', :time => Time.now }
      options[:message] ||= "Initial commit"
      options[:parents] = []
      options[:update_ref] = 'HEAD'
      options[:tree] = @repo.index.write_tree(@repo)
      Rugged::Commit.create(@repo, options)
    end
  end

  def current_version
    @repo.head.resolve.target.oid
  end

  def walker_for_version(version)
    walker = Rugged::Walker.new(@repo)

    walker.sorting(Rugged::SORT_DATE)
    walker.push(version)

    return walker
  end
  def lookup(oid)
    @repo.lookup(oid)
  end

  def update_config_file(path, new_file, author, commit_message)
    FileUtils.cp(new_file, @repo.workdir+'/'+path)
    update_path(path, author, commit_message)
  end
  def update_path(path, author, commit_message)
    index = @repo.index
    index.add(path)
    index.write

    tree = index.write_tree

    if(author.nil?)
      author_hash = {:email => '-1', :name => 'no_author_given', :time => Time.now}
    else
      author_hash = {:email => author.id.to_s, :name => author.username, :time => Time.now}
    end

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
  def text_at_version(path, version = nil)
    version = current_version if version.nil?

    file_blob = file_at_version(path, version)
    return nil if file_blob.nil?

    return file_blob.text
  end
  def file_exists_at_version?(path, version = nil)
    version = current_version if version.nil?

    file = file_at_version(path, version)
    return (not file.nil?)
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

    target_node = tree[path_components[0]]
    return nil if target_node.nil?
    target_oid = target_node[:oid]
    return nil if target_oid.nil?
    return nil unless @repo.exists?(target_oid)

    target = @repo.lookup(target_oid)

    return access_tree_by_path(target, path_components[1])
  end
end
