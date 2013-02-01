class GitConfigRepository
  def initialize
    begin
      @repo = Rugged::Repository.new(Rails.application.config.data_directory)
    rescue Rugged::OSError, Rugged::RepositoryError
      @repo = Rugged::Repository.init_at(Rails.application.config.data_directory, false)
    end    
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
end
