class KeyPathAccessor
  def self.access_by_path(value, path)
    return value if path.nil? || value.nil?

    path_components = path.delete(']').split('[', 2)

    result = if value.is_a? Array
               value[path_components[0].to_i]
             else
               value[path_components[0]]
             end

    access_by_path(result, path_components[1])
  end

  def self.set_by_path(value, path, new_value)
    return value if path.nil? || value.nil?

    path_components = path.delete(']').split('[', 2)

    if value.is_a? Array
      value[path_components[0].to_i] = (path_components[1].blank? ? new_value : set_by_path(value[path_components[0].to_i], path_components[1], new_value))
    else
      value[path_components[0]] = (path_components[1].blank? ? new_value : set_by_path(value[path_components[0]], path_components[1], new_value))
    end

    value
  end
end
