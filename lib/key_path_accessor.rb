class KeyPathAccessor
  def self.access_by_path(value, path)
   if (path.nil? or value.nil?)
      return value 
    end
    
    path_components = path.gsub(/\]/,'').split('[', 2)
    
    if(value.is_a? Array)
      result = value[path_components[0].to_i]
    else
      result = value[path_components[0]]
    end
    
    return access_by_path(result, path_components[1])
  end
end
