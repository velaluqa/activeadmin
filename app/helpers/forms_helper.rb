require 'key_path_accessor'

module FormsHelper
  def validators_hash(field)
    attributes = {}

    if(field[:is_repeatable])
      attributes["data-no-validation"] = true
    end

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

  def form_answer_for_case(c)
    if c.is_a?(FormAnswer)
      c
    else
      c.form_answer
    end
  end
  def case_for_case(c)
    if c.is_a?(FormAnswer)
      c.case
    else
      c
    end
  end

  def options_from_values(field, selected_values, no_default = false, additional_options = [])
    values = field['values']
    values = {} if values.nil?
    if no_default
      options = ''
    else
      options = '<option value="">Please select</option>'
    end

    options += additional_options.join('')

    values.each do |value, label|
      selected = ((selected_values and selected_values.include?(value)) ? " selected=\"selected\"" : "")
      options += "<option data-permanent-select-option=\"true\" value=\"#{value}\" #{selected}>#{label}</option>"
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

  def results_table_columns(cases, merge = false)
    return [] if cases.empty?

    cases = Array.new(cases) # make a copy so we can empty it locally

    columns = [[cases.shift]]

    cases.each do |c|
      if merge and columns.last.last.patient_id == c.patient_id and columns.last.last.images == c.images
        columns.last << c
      else
       columns << [c]
      end
    end

    return columns
  end

  def results_table_answer_for_column(column, row_spec, repeatable)
    answer = nil
    the_case = nil
    the_value = nil
    column.each do |c|
      value = (row_spec['value'].nil? ? row_spec['values'][c.case_type] : row_spec['value'])

      unless value.nil?
        unless repeatable.nil?
          prefix = repeatable[:prefixes][c.case_type]
          full_value = "#{prefix}[#{repeatable[:index]}][" + value + ']'
        else
          full_value = value
        end

        answer = results_table_find_answer(c, full_value)
      else
        answer = nil
      end

      unless answer.nil?
        the_case = c
        the_value = value
        break
      end
    end

    return [answer, the_case, the_value]
  end
  def results_table_find_answer(the_case, value)
    return nil if value.nil?

    answer = nil
    if value.start_with?('patient[') or value.start_with?('case[')
      answer = KeyPathAccessor::access_by_path(the_case.data_hash, value)
    elsif(the_case.form_answer)
      answer = KeyPathAccessor::access_by_path(the_case.form_answer.answers, value)
    else
      answer = nil
    end

    return answer
  end

  def adjudication_results_table_answers_for_column(column, row_spec, repeatable)
    answers = []
    cases = []
    values = []
    column.each do |c|
      value = c.nil? ? nil : (row_spec['value'].nil? ? row_spec['values'][c.case_type] : row_spec['value'])

      unless value.nil?
        unless repeatable.nil?
          prefix = repeatable[:prefixes][c.case_type]
          full_value = "#{prefix}[#{repeatable[:index]}][" + value + ']'
        else
          full_value = value
        end

        answers << results_table_find_answer(c, full_value)
      else
        answers << nil
      end

      cases << c
      values << value
    end

    return [answers, cases, values]
  end

  def answer_specs_for_repeatable(cases, keys, form_answer_field_maps, repeatable_spec)
    answer_specs = cases.each_with_index.map do |c, i|
      if form_answer_field_maps[c.id].nil?
        nil
      elsif repeatable_spec[:prefixes][c.case_type].nil?
        nil
      elsif keys[i].nil?
        nil
      else
        form_answer_field_maps[c.id][1][repeatable_spec[:prefixes][c.case_type]][keys[i]]
      end
    end

    return answer_specs
  end

  def results_table_format_answer(answer, answer_spec)
    if answer_spec.nil?
      format_fixed_value(answer)
    else
      simple_format(FormAnswer.pretty_print_answer(answer_spec, answer, nil, false))
    end
  end

  def value_for_reopened_case(field, reopened_case)
    return nil if (reopened_case.form_answer.nil? or reopened_case.form_answer.answers.nil?)
    KeyPathAccessor::access_by_path(reopened_case.form_answer.answers, field['id'])
  end

  def max_number_of_repeatable_items(cases)
    column_sizes = cases.map do |cs|
      let max_of_cases = cs.map do |c|
        if (c.form_answer and c.form_answer.answers) then
          c.form_answer.answers[prefixes[c.case_type]].nil? ? 0 : (c.form_answer.answers[prefixes[c.case_type]].size || 0)
        else 0
        end
      end

      max_of_cases.empty? ? 0 : max_of_cases.max
    end
    column_sizes.empty? ? 0 : max_of_cases.max
  end
end
