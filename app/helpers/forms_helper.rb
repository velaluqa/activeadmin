module FormsHelper
  def validators_hash(field)
    attributes = {}
    return attributes if field['validations'].nil?

    field['validations'].each do |validation|
      message = validation.delete('message')
      next if validation.size != 1
      
      type, value = validation.first

      attributes["data-validation-#{type}-message"] = message unless message.nil?
      attributes["data-validation-#{type}-#{type}"] = value
    end

    return attributes
  end

  def options_from_values(field)
    values = field['values']
    options = "<option value=\"\">Please select</option>"

    values.each do |value, label|
      options += "<option value=\"#{value}\">#{label} (#{value})</option>"
    end

    return options
  end

  def roi_values_data_fields(field)
    values = field['values']
    data_fields = {}
    
    values.each do |key,value|
      data_fields[:"data-roi-value-#{key}"] = value
    end
  end
end
