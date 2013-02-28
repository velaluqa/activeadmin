module ConfigDisplayFilters
  def self.filter_session_config(config)
    config['types'].each do |name,t|
      t['annotations_layout'] = '<cut for display>' unless t['annotations_layout'].nil?
      t['validation']['annotations_layout'] = '<cut for display>' unless (t['validation'].nil? or  t['validation']['annotations_layout'].nil?)
    end
  end
end
