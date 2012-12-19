each = (arr, func, index=0) ->
  if index < arr.length then [ func(arr[index], index), each(arr, func, index + 1)... ] else []

capitalize = (input) ->
  input.charAt(0).toUpperCase() + input.slice(1)

camelize = (input) ->
  pieces = input.split(/[\W_-]/)
  each(pieces, capitalize).join("")

has_pharmtrace_api = ->
  PharmTraceAPI?

roi_to_options = (roi, type) ->
  new Option("Name: "+roi['name']+", "+camelize(type)+": "+roi[type], roi[type], false, false)

populate_select_with_rois = (select, rois) ->
  type = /select-roi-(.*)/.exec(select.className)[1]
  select_id = select.id
  select = $('#'+select_id)
  select.empty()
  select.append(roi_to_options(roi, type)) for roi in rois when (type of roi)

  if($('#'+select_id+' option').length == 0)
    select.append(new Option("No ROIs available", "", true, true))

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

display_answers_preview = (answers) ->
  preview_modal = $('#preview_modal')  
  data_fields = preview_modal.find('.modal-body span')

  fill_data_field($(field), answers) for field in data_fields

  preview_modal.modal('show')  

fill_print_version = (answers) ->
  print_version = $('#print_version')  
  data_fields = print_version.find('.print-body span')

  fill_data_field($(field), answers) for field in data_fields

fill_data_field = (field, answers) ->
  field_name = field.attr('name')
  return unless field_name?
  answer = value_at_path(answers, field_name)

  if(field.attr('data-type') == 'bool')
    answer = if answer == yes then "Yes" else "No"

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

$(document).ready ->
  jq_bootstrap_validation_settings = {
      submitSuccess: ($form, event) ->
        event.preventDefault()

        clear_custom_validation_messages()

        if(!window.custom_validation_functions? || window.custom_validation_functions.length == 0)
          return

        validation_messages = (validator_func($form) for validator_func in window.custom_validation_functions)
        validation_messages = validation_messages.reduce (acc,v) -> acc.concat(v)

        if(validation_messages.length > 0)
          set_custom_validation_messages(validation_messages)
        else
          #form_data = transform_answers_array($('#the_form').serializeArray())
          form_data = find_arrays($('#the_form').formParams())
          window.form_answers = form_data
          fill_print_version(form_data)
          display_answers_preview(form_data)
  }

  $("#the_form input,select,textarea").not("[type=submit]").jqBootstrapValidation(jq_bootstrap_validation_settings)

  $('.add-repeat-btn').click ->
    repeatable_id = $(this).attr('data-id')
    console.log("Adding #{repeatable_id}")

    elements = find_arrays($('#the_form').formParams())[repeatable_id]
    index = elements.length
    console.log("Currently included #{elements.length} times")

    group_end = $("#repeatable_group_end_#{repeatable_id}")
    repeatable = $("#repeatable_#{repeatable_id}").clone()
    set_index_in_name_and_id(repeatable.find('input,select,textarea'), index)
    set_index_in_for(repeatable.find('label'), index)
    console.log(group_end)
    console.log(repeatable)

    group_end.before(repeatable)
    #$("#the_form input,select,textarea").not("[type=submit]").jqBootstrapValidation(jq_bootstrap_validation_settings)
  
  $('#refresh-rois-btn').click ->
    $(this).button('loading')
    PharmTraceAPI.updateROIs()

  PharmTraceAPI.roisUpdated.connect ->  
    rois = PharmTraceAPI.rois
    console.log($('[class*="select-roi-"]'))
    populate_select_with_rois(select, rois) for select in $('[class*="select-roi-"]')
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
    
    