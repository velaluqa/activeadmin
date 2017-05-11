module ConfigDisplayFilters
  def self.filter_session_config(config)
    return config if config.nil? || config['types'].nil? || !config['types'].respond_to?(:each)

    config['types'].each do |_name, t|
      t['annotations_layout'] = '<cut for display>' unless t['annotations_layout'].nil?
      t['validation']['annotations_layout'] = '<cut for display>' unless t['validation'].nil? || t['validation']['annotations_layout'].nil?
    end

    config
  end
end
