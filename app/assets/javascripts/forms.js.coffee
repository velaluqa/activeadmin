each = (arr, func, index=0) ->
  if index < arr.length then [ func(arr[index], index), each(arr, func, index + 1)... ] else []

capitalize = (input) ->
  input.charAt(0).toUpperCase() + input.slice(1)

camelize = (input) ->
  pieces = input.split(/[\W_-]/)
  each(pieces, capitalize).join("")

has_pharmtrace_api = ->
  PharmTraceAPI?

create_option = (text, value) ->
  $('<option></option>').val(value).html(text)

roi_to_options = (roi, values) ->
  label = "Name: "+roi['name']+", "
  option_value = {}

  for own key, value of values
    label = label + camelize(value)+": "+roi[value]+", "
    option_value[key] = roi[value]

  label = label.slice(0, -2)
    
  create_option(label, JSON.stringify(option_value))

roi_has_values = (roi, values) ->
  (return false if !(value of roi)) for own _,value of values

  return true

populate_select_with_rois = (select, rois) ->
  select = $(select)

  values = jQuery.parseJSON(select.attr('data-roi-values'))
  
  select.empty()
  select.append(create_option("Please select", ""))
  select.append(roi_to_options(roi, values)) for roi in rois when roi_has_values(roi, values)

register_custom_validation_function = (func) ->
  window.custom_validation_functions = [] unless window.custom_validation_functions?
  window.custom_validation_functions.push(func)

window.register_custom_validation_function = register_custom_validation_function

clear_custom_validation_messages = ->
  $('#custom-validation-help-block').empty()

set_custom_validation_messages = (messages) ->
  help_block = $('#custom-validation-help-block')

  help_block.append('<ul role="alert"></ul>')
  ul = $('#custom-validation-help-block ul')

  lis = ('<li>'+message+'</li>' for message in messages)

  ul.append(lis.join('\n'))

fill_placeholder_cells = (root_elem, answers) ->
  placeholder_cells = $(root_elem).find('td.results-table-placeholder-cell')

  fill_data_field($(cell), answers) for cell in placeholder_cells

fill_data_field = (field, answers) ->
  field_name = field.attr('name')
  return unless field_name?
  answer = value_at_path(answers, field_name)

  if(field.attr('data-type') == 'bool')
    answer = if answer == yes then "Yes" else "No"
  else if(field.attr('data-type') == 'roi')
    answer_html = (('<p>'+key+": "+value+'</p>') for own key,value of answer)

  if(answer_html?)
    field.html(answer_html)
  else
    field.text(answer)

value_at_path = (obj, path) ->
  components = (component.replace(/\[/, "").replace(/\]/, "") for component in path.split("["))

  current_obj = obj
  for component in components
    component = parseInt(component, 10) if (/^[0-9]*$/.test(component))
    
    current_obj = current_obj[component]

  current_obj

is_array = (obj) ->
  return false unless (typeof obj == 'object')
  
  numbers = ((/^[0-9]*/.test(key)) for own key, value of obj)

  numbers.reduce (a,b) -> a and b

convert_to_array = (value) ->
  return value unless is_array(value)

  array = []
  for own key, v of value
    array[parseInt(key, 10)] = v

  array

find_arrays = (answers) ->  
  (answers[key] = convert_to_array(value)) for own key, value of answers
  answers

set_index_in_name = (elements, index) ->
  for element in elements
    name = $(element).attr('name').replace(/\[\]/, "[#{index}]")

    $(element).attr('name', name)
set_index_in_name_and_id = (elements, index) ->
  for element in elements
    name = $(element).attr('name').replace(/\[\]/, "[#{index}]")
    id = $(element).attr('id').replace(/__/, "_#{index}_")

    $(element).attr('name', name)
    $(element).attr('id', id)
set_index_in_for = (elements, index) ->
  for element in elements
    name = $(element).attr('for').replace(/__/, "_#{index}_")

    $(element).attr('for', name)

delay = (ms, func) -> window.setTimeout(func, ms)

$(document).ready ->
  $("#the_form input,select,textarea").not("[type=submit]").jqBootstrapValidation(
        submitSuccess: ($form, event) ->
          event.preventDefault()

          clear_custom_validation_messages()

          if(window.custom_validation_functions? && window.custom_validation_functions.length > 0)
            validation_messages = (validator_func($form) for validator_func in window.custom_validation_functions)
            validation_messages = validation_messages.reduce (acc,v) -> acc.concat(v)

            if(validation_messages.length > 0)
              set_custom_validation_messages(validation_messages)
              return
              
          form_data = find_arrays($('#the_form').formParams())
          console.log(form_data)
          window.form_answers = form_data
          fill_placeholder_cells($('#preview_modal'), form_data)
          fill_placeholder_cells($('#print_version'), form_data)
          $('#preview_modal').modal('show')  
  )

  $('.add-repeat-btn').click ->
    repeatable_id = $(this).attr('data-id')
    console.log("Adding #{repeatable_id}")

    console.log($('#the_form'))
    console.log($('#the_form').formParams())
    elements = find_arrays($('#the_form').formParams())[repeatable_id]
    index = if elements? then elements.length else 0

    console.log(index)
    console.log(parseInt($(this).attr('data-max-repeats'), 10))
    return if (index == parseInt($(this).attr('data-max-repeats'), 10))
    
    console.log("Currently included #{index} times")

    group_end_form = $("#repeatable_group_end_form_#{repeatable_id}")
    repeatable_form = $("#repeatable_form_#{repeatable_id}").clone()
    set_index_in_name_and_id(repeatable_form.find('input,select,textarea'), index)
    set_index_in_for(repeatable_form.find('label'), index)
    repeatable_form.find('.form-group-index').text(index+1)
    console.log(group_end_form)
    console.log(repeatable_form)

    scroll_to_element = group_end_form.before(repeatable_form.children().first()).prev()
    group_end_form.before(e) for e in repeatable_form.children()

    repeatable_preview = $("#repeatable_table_#{repeatable_id} tbody").clone()
    repeatable_preview.find('.form-group-index-cell').text(index+1)
    set_index_in_name(repeatable_preview.find('td.results-table-placeholder-cell'), index)

    $("#repeatable_group_end_preview_#{repeatable_id}").before(e) for e in repeatable_preview.clone().children()
    $("#repeatable_group_end_print_#{repeatable_id}").before(e) for e in repeatable_preview.children()
    
    repeatable_form.find("input,select,textarea").not("[type=submit]").jqBootstrapValidation()

    delay 10, -> 
      $(window).scrollTop(scroll_to_element.position().top-20);

  $('#refresh-rois-btn').click ->
    $(this).button('loading')
    PharmTraceAPI.updateROIs()

  PharmTraceAPI.roisUpdated.connect ->  
    rois = PharmTraceAPI.rois
    selects = $('.select-roi')

    populate_select_with_rois(select, rois) for select in selects
    $('#refresh-rois-btn').button('reset')

  $('#preview_submit_btn').click ->
    $(this).button('loading')

    PharmTraceAPI.submitAnswers(window.form_answers)

  PharmTraceAPI.answersSubmitted.connect (success) ->
    console.log("submitting answers: #{success}")
    
    $('#preview_submit_btn').button('reset')
    $('#preview_modal').modal('hide')
    
  PharmTraceAPI.answerSubmissionAborted.connect (success) ->
    console.log("answers not submitted, aborted")
    
    $('#preview_submit_btn').button('reset')
    
    