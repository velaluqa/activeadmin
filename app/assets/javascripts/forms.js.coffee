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

$(document).ready ->
  $("input,select,textarea").not("[type=submit]").jqBootstrapValidation(
    submitSuccess: ($form, event) ->
      event.preventDefault()

      clear_custom_validation_messages()

      if(!window.custom_validation_functions? || window.custom_validation_functions.length == 0)
        return

      validation_messages = (validator_func($form) for validator_func in window.custom_validation_functions)
      validation_messages = validation_messages.reduce (acc,v) -> acc.concat(v)

      if(validation_messages.length > 0)
        set_custom_validation_messages(validation_messages)

        event.preventDefault()
  )
  
  $('#refresh-rois-btn').click ->
    PharmTraceAPI.updateROIs()

    rois = PharmTraceAPI.rois
    populate_select_with_rois(select, rois) for select in $('[class*="select-roi-"]')