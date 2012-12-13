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

apply_type = (value, preview_field) ->
  type = $(preview_field).attr('data-type')

  if(type == 'number' || type == 'roi')
    return parseFloat(value, 10)
  else if(type == 'bool')
    return value > 0
  else
    return value

transform_answers_array = (array) ->
  result = new Object

  (result[answer['name']] = apply_type(answer['value'], $("#preview_modal .modal-body span[name='#{answer['name']}']"))) for answer in array

  return result

display_answers_preview = (answers) ->
  preview_modal = $('#preview_modal')  
  data_fields = preview_modal.find('.modal-body span')

  fill_data_field($(field), answers) for field in data_fields

  preview_modal.modal('show')  

fill_data_field = (field, answers) ->
  field_name = field.attr('name')
  answer = answers[field_name]

  if(field.attr('data-type') == 'bool')
    answer = if answer == yes then "Yes" else "No"

  field.text(answer)

$(document).ready ->
  $("#the_form input,select,textarea").not("[type=submit]").jqBootstrapValidation(
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
        form_data = transform_answers_array($('#the_form').serializeArray())
        window.form_answers = form_data
        display_answers_preview(form_data)
  )
  
  $('#refresh-rois-btn').click ->
    $(this).button('loading')
    PharmTraceAPI.updateROIs()

  PharmTraceAPI.roisUpdated.connect ->  
    rois = PharmTraceAPI.rois
    populate_select_with_rois(select, rois) for select in $('[class*="select-roi-"]')
    $('#refresh-rois-btn').button('reset')

  $('#preview_submit_btn').click ->
    $(this).button('loading')

    PharmTraceAPI.submitAnswers(window.form_answers)

  PharmTraceAPI.answersSubmitted.connect (success) ->
    console.log("submitting answers: #{success}")
    
    $('#preview_submit_btn').button('reset')
    $('#preview_modal').modal('hide')
    
    