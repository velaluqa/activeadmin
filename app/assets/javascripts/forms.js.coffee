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

roi_to_option = (roi, values) ->
  option = $('<option></option>').attr('data-roi-id', roi['roi_id'])
  option = update_roi_option(option, values)

  return option

update_roi_option = (option, values) ->
  option = $(option)
  roi = window.rois[option.attr('data-roi-id')]
  return null unless roi?
  return null unless roi_has_values(roi, values)
  
  label = "Name: "+roi['name']+", "
  option_value = {}

  option_value['location'] = {}
  option_value['location']['seriesUID'] = roi['seriesUID']
  option_value['location']['imageIndex'] = roi['instanceNumber']
  option_value['location']['sopInstanceUID'] = roi['sopInstanceUID']

  for own key, value of values
    label = label + camelize(value)+": "+roi[value]+", "
    option_value[key] = roi[value]

  label = label.slice(0, -2)

  option.html(label)
  option.val(JSON.stringify(option_value))

  return option
  
roi_has_values = (roi, values) ->
  (return false if !(value of roi)) for own _,value of values

  return true

update_roi_select = (select) ->
  select = $(select)

  values = jQuery.parseJSON(select.attr('data-roi-values'))

  options = select.find('option[value]').not('[value=""]').not('[data-permanent-select-option="true"]')
  existing_ids = []
  for option in options
    if update_roi_option(option, values)?      
      existing_ids += $(option).attr('data-roi-id')
    else
      $(option).remove()

  select.append(roi_to_option(roi, values)) for own roi_id, roi of window.rois when (!(roi_id in existing_ids) and roi_has_values(roi, values))

  if(select.find('option') <= 1)
    select.find('option').first().html('No ROIs available')
  else
    select.find('option').first().html('Please Select')
    
  if(select.find('option:selected').length == 0)
    select.find('option:not([value])').attr('selected', 'selected')

update_enabled_options = (select) ->
  for option in $(select).find('option[value]')
    option = $(option)
    roi = window.rois[option.attr('data-roi-id')]
    continue unless roi?
    selected_by_select = roi['selected_by_select']
  
    if selected_by_select? and selected_by_select != $(select).attr('id')
      option.attr('disabled', 'disabled')
    else
      option.removeAttr('disabled')

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
  else if(field.attr('data-type') == 'roi') and (typeof answer == 'object')
    location_html = '<p>Location: '+answer['location']['seriesUID']+' #'+answer['location']['imageIndex'].toString()+'</p>'
    answer_html = location_html+(('<p>'+key+": "+value+'</p>') for own key,value of answer when key != 'location').join("\n")      
  else if(field.attr('data-type') == 'select') or ((field.attr('data-type') == 'roi') and (typeof answer == 'string'))
    select_input = $('select[name="'+field_name+'"]')
    answer_option = select_input.find('option[value="'+answer+'"]').text()
    answer = if answer_option? and answer_option.length > 0 then answer_option else answer
  else if(field.attr('data-type') == 'select_multiple')
    select_input = $('select[name="'+field_name+'"]')    
    select_input = $('select[name="'+field_name+'[]"]') if select_input.length == 0
    answer_html = for value in answer
      option = select_input.find('option[value="'+value+'"]').text()
      '<p>'+(if option? and option.length > 0 then option else value)+'</p>'
    answer_html = answer_html.join("\n")

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
  
  numbers = ((/^[0-9]*$/.test(key)) for own key, value of obj)

  return true if numbers.length == 0
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

update_allowed_rois = (changed_select) ->
  changed_select = $(changed_select)

  selected_option = changed_select.find('option:selected')
  return if selected_option.length == 0

  new_selection = changed_select.find('option:selected').attr('data-roi-id')
  old_selection = changed_select.data('old_selection')

  window.rois[old_selection]['selected_by_select'] = null if old_selection?
  window.rois[new_selection]['selected_by_select'] = changed_select.attr('id') if new_selection?

  selects = $('.select-roi').not(changed_select)
  update_enabled_options(select) for select in selects

  if(selected_option.val().length == 0)
    changed_select.removeData('old_selection')
  else
    changed_select.data('old_selection', new_selection)

find_roi_id_by_data = (roi) ->
  for own roi_id,old_roi of window.rois
    if(old_roi['length'] == roi['length'] and
       old_roi['area'] == roi['area'] and
       old_roi['min'] == roi['min'] and
       old_roi['max'] == roi['max'] and
       old_roi['mean'] == roi['mean'] and
	   old_roi['seriesUID'] == roi['seriesUID'] and
	   old_roi['instanceNumber'] == roi['instanceNumber'])
      return roi_id

  return null

update_rois_table = (new_rois) ->
  console.log("UPDATING ROI TABLE---------------")
  for roi in new_rois
    console.log("Updating ROI: ")
    console.log(roi)
    roi_id = null
    roi_name = roi['seriesUID']+'/'+roi['name']
    console.log("ROI name: "+roi_name)
    if window.osirix_id_to_roi_id[roi['id']]?
      roi_id = window.osirix_id_to_roi_id[roi['id']]
      console.log("found ROI ID via OsiriX ID: "+roi_id)
    else if window.name_to_roi_id[roi_name]?
      roi_id = window.name_to_roi_id[roi_name]
      console.log("found ROI ID via name: "+roi_id)
    else
      roi_id = find_roi_id_by_data(roi)
      console.log("found ROI ID via data: "+roi_id) if roi_id?
      console.log("assigning new ROI ID: "+window.next_roi_id) unless roi_id?
      roi_id = window.next_roi_id++ unless roi_id?

    window.osirix_id_to_roi_id[roi['id']] = roi_id
    console.log("updated osirix_id_to_roi_id: "+window.osirix_id_to_roi_id[roi['id']])
    window.name_to_roi_id[roi_name] = roi_id
    console.log("updated name_id_to_roi_id: "+window.name_to_roi_id[roi_name])

    roi['roi_id'] = roi_id
    roi['selected_by_select'] = window.rois[roi_id]['selected_by_select'] if window.rois[roi_id]?

    window.rois[roi_id] = roi
    console.log("updated ROI table:")
    console.log(window.rois[roi_id])

update_rois = ->
  rois = PharmTraceAPI.rois
  update_rois_table(rois)

  selects = $('.select-roi')
  update_roi_select(select) for select in selects

update_nav_button_state = ->
  if $('#form_nav_select option').first().attr('selected') == 'selected'
    $('#form_nav_previous_btn').attr('disabled', 'disabled')
    $('#form_nav_next_btn').removeAttr('disabled')
  else if $('#form_nav_select option').last().attr('selected') == 'selected'
    $('#form_nav_previous_btn').removeAttr('disabled')
    $('#form_nav_next_btn').attr('disabled', 'disabled')
  else
    $('#form_nav_previous_btn').removeAttr('disabled')
    $('#form_nav_next_btn').removeAttr('disabled')  

update_calculated_field = (field) ->
  field = $(field)
  hidden_field = $('.calculated-hidden-field[id="'+field.attr('name')+'"]')

  calculation_function = field.attr('data-calculation-function')
  unless calculation_function? and @[calculation_function]?
    console.error('Calculated field "'+field.attr('name')+'" specifies an invalid calculation function "'+calculation_function+'"')
    return

  [display_value, value] = @[calculation_function](window.results_list)
  field.html(display_value)
  hidden_field.val(value) if hidden_field?

update_calculated_fields = ->
  update_results_list()
  update_calculated_field(field) for field in $('.calculated-field')

update_results_list = ->
  current_result = window.results_list[window.results_list.length-1]
  current_result.answers = find_arrays($('#the_form').formParams())

calculate_decimals_for_step = (step) ->
  decimals = 0
  while(step < 1)
    decimals += 1
    step *= 10

  return decimals

validate_number_inputs = ->
  success = true
  
  for number_input in $('input[type=number]')
    $number_input = $(number_input)

    step = parseFloat($number_input.prop('step'))
    value = parseFloat($number_input.val())
    power = Math.pow(10, calculate_decimals_for_step(step))

    help_block = $number_input.siblings('.help-block')
    control_group = $number_input.closest('.control-group')

    help_block.html('')
    control_group.removeClass('error')

    unless(Math.abs(Math.round(value*power) - value*power) < 0.00001) # epsilon calculation, since floating point math in JS is rediculously bad

      help_block.html("<ul role=\"alert\"><li>Invalid number, must be a mulitple of #{step}</li></ul>")
      control_group.addClass('error')
      success = false

  return success
  
display_validation_success = (success) ->
  if(success)
    $('#the_form .submit-errors').text('')
  else
    $('#the_form .submit-errors').text('Validation Errors present')
  
$(document).ready ->
  window.rois = {}
  window.next_roi_id = 0
  window.osirix_id_to_roi_id = {}
  window.name_to_roi_id = {}
  window.body_padding = $('body').css('padding-top').replace('px', '')

  $(".datepicker-field").datepicker()

  update_calculated_fields()
      
  $("#the_form input,select,textarea").not("[type=submit]").jqBootstrapValidation(  
        submitSuccess: ($form, event) ->
          event.preventDefault()

          unless validate_number_inputs()
            display_validation_success(false)
            return            

          clear_custom_validation_messages()

          form_data = find_arrays($('#the_form').formParams())
          console.log(form_data)

          # create a clone so even if custom validators change the values, we don't use the changes
          form_data_clone = jQuery.extend(true, {}, form_data)

          if(window.custom_validation_functions? && window.custom_validation_functions.length > 0)
            validation_messages = (validator_func(form_data_clone) for validator_func in window.custom_validation_functions)
            validation_messages = validation_messages.reduce (acc,v) -> acc.concat(v)

            if(validation_messages.length > 0)
              set_custom_validation_messages(validation_messages)
              display_validation_success(false)
              return

          display_validation_success(true)
              
          window.form_answers = form_data
          fill_placeholder_cells($('#preview_modal'), form_data)
          fill_placeholder_cells($('#print_version'), form_data)
          $('#preview_modal').modal('show')
        submitError: ($form, event, errors) ->
          console.log("SUBMIT ERROR:")
          for own field, field_errors of errors
            console.log("Field: "+field)
            for error in field_errors
              console.log("Error: "+error)
          display_validation_success(false)
  )

  $('#form_nav_select').change ->
    target = $('#'+$(this).val())
    console.log(target)
    $(window).scrollTop(target.position().top);
    update_nav_button_state()
    update_calculated_fields()

  $('#form_nav_previous_btn').click ->  
    return false if $(this).attr('disabled') == 'disabled'
    
    nav_select = $('#form_nav_select')
    current_value =  nav_select.find('option:selected').val()
    previous_value = nav_select.find('option:selected').prev().val()

    update_calculated_fields()

    unless previous_value == current_value
      nav_select.val(previous_value)
      nav_select.change()
      update_nav_button_state()

    return false
  $('#form_nav_next_btn').click ->
    return false if $(this).attr('disabled') == 'disabled'

    nav_select = $('#form_nav_select')
    current_value =  nav_select.find('option:selected').val()
    next_value = nav_select.find('option:selected').next().val()

    update_calculated_fields()

    unless next_value == current_value
      nav_select.val(next_value)
      nav_select.change()
      update_nav_button_state()

    return false

  $('.add-repeat-btn').click ->
    repeatable_id = $(this).attr('data-id')
    console.log("Adding #{repeatable_id}")

    #console.log($('#the_form'))
    #console.log($('#the_form').formParams())
    elements = find_arrays($('#the_form').formParams())[repeatable_id]
    index = if elements? then elements.length else 0

    #console.log(index)
    #console.log(parseInt($(this).attr('data-max-repeats'), 10))
    return if (index == parseInt($(this).attr('data-max-repeats'), 10))
    
    console.log("Currently included #{index} times")

    group_end_form = $("#repeatable_group_end_form_#{repeatable_id}")
    repeatable_form = $("#repeatable_form_#{repeatable_id}").clone()
    set_index_in_name_and_id(repeatable_form.find('input,select,textarea'), index)
    set_index_in_for(repeatable_form.find('label'), index)
    repeatable_form.find('.form-group-index').text(index+1)
    #console.log(group_end_form)
    #console.log(repeatable_form)

    repeatable_form.find('.select-roi').change ->
      update_allowed_rois($(this))
    repeatable_form.find('.select-roi').mousedown ->
      PharmTraceAPI.updateROIsSynchronously()
      update_rois()
    repeatable_form.find("input,select,textarea").not("[type=submit]").jqBootstrapValidation()

    scroll_to_element = group_end_form.before(repeatable_form.children().first()).prev()
    group_end_form.before(e) for e in repeatable_form.children()

    repeatable_preview = $("#repeatable_table_#{repeatable_id} tbody").clone()
    repeatable_preview.find('.form-group-index-cell').text(index+1)
    set_index_in_name(repeatable_preview.find('td.results-table-placeholder-cell'), index)

    $("#repeatable_group_end_preview_#{repeatable_id}").before(e) for e in repeatable_preview.clone().children()
    $("#repeatable_group_end_print_#{repeatable_id}").before(e) for e in repeatable_preview.children()

    delay 10, -> 
      $(window).scrollTop(scroll_to_element.position().top-window.body_padding);

  $('.select-roi').mousedown ->
    PharmTraceAPI.updateROIsSynchronously()
    update_rois()

  $('#recalc-btn').click ->
    $(this).button('loading')
    update_calculated_fields()
    $(this).button('reset')

  $('#refresh-rois-btn').click ->
    $(this).button('loading')
    PharmTraceAPI.updateROIs()

  PharmTraceAPI.roisUpdated.connect ->
    #rois = jQuery.parseJSON('[{"id":1,"length":23.42,"name":"Length","seriesModality":"CT","seriesName":"Test Series 1","seriesUID":"1.2.3.4.5","sliceLocation":1,"studyName":"Test Study"},{"area":42.23,"id":23,"max":5,"mean":4.23,"min":3,"name":"Area","seriesModality":"MRT","seriesName":"Test Series 2","seriesUID":"5.4.3.2.1","sliceLocation":7,"studyName":"Test Study"},{"area":65,"id":42,"length":7,"max":23,"mean":7.4223,"min":-1,"name":"MegaROI","seriesModality":"PET","seriesName":"Test Series 2","seriesUID":"5.4.3.2.1","sliceLocation":23,"studyName":"Test Study"}]')
    update_rois()
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
    
  PharmTraceAPI.aboutToPrintPaperTrail.connect ->
    date_string = moment().format('DD.MM.YYYY HH:mm:ss')
    $('#print_timestamp').text("Submission Date: "+date_string)

  PharmTraceAPI.annotatedImagesAvailable.connect (annotated_images) ->
    console.log("putting annotated images into paper trail")
    console.log(annotated_images)

    # clear already inserted images (in case this is not the first attempt to submit the form
    $('#print_annotated_images_table_header_row ~ tr').remove()
    
    table_header_row = $('#print_annotated_images_table_header_row')
    
    for own series, images of annotated_images
      for own image, checksum of images
        table_header_row.after($('<tr><td>'+image+'</td><td>'+checksum+'</td></tr>'))
    
  $('.select-roi').change ->
    update_allowed_rois($(this))