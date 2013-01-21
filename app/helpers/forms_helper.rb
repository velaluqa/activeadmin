require 'key_path_accessor'

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

  def options_from_values(field, selected_value)
    values = field['values']
    options = "<option value=\"\">Please select</option>"

    values.each do |value, label|
      selected = (value == selected_value ? " selected=\"selected\"" : "")
      options += "<option value=\"#{value}\" #{selected}>#{label} (#{value})</option>"
    end

    return options
  end

  def fixed_value(field, data)
    return [nil,{}] if (field['fixed_value'].nil? or
                        !field['fixed_value'].is_a?(String) or
                        field['fixed_value'].empty?)

    key_path = field['fixed_value']
    value = KeyPathAccessor::access_by_path(data, key_path)

    return [value, {:disabled => true}]
  end

  def format_fixed_value(value)
    return '' if value.nil?

    case value
    when Date, DateTime, Time
      value.strftime('%d.%m.%Y')
    when TrueClass
      'Yes'
    when FalseClass
      'No'
    else
      value.to_s
    end
  end
end
