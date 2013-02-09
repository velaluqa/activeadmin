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

  options = select.find('option[value]').not('[value=""]')
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
       old_roi['mean'] == roi['mean'])
      return roi_id

  return null

update_rois_table = (new_rois) ->
  for roi in new_rois
    roi_id = null
    roi_name = roi['seriesUID']+'/'+roi['name']
    if window.osirix_id_to_roi_id[roi['id']]?
      roi_id = window.osirix_id_to_roi_id[roi['id']]
    else if window.name_to_roi_id[roi_name]?
      roi_id = window.name_to_roi_id[roi_name]
    else
      roi_id = find_roi_id_by_data(roi)
      roi_id = window.next_roi_id++ unless roi_id?

      window.osirix_id_to_roi_id[roi['id']] = roi_id
      window.name_to_roi_id[roi_name] = roi_id

    roi['roi_id'] = roi_id
    roi['selected_by_select'] = window.rois[roi_id]['selected_by_select'] if window.rois[roi_id]?

    window.rois[roi_id] = roi

$(document).ready ->
  window.rois = {}
  window.next_roi_id = 0
  window.osirix_id_to_roi_id = {}
  window.name_to_roi_id = {}

  $(".datepicker-field").datepicker()
      
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
    repeatable_form.find("input,select,textarea").not("[type=submit]").jqBootstrapValidation()

    scroll_to_element = group_end_form.before(repeatable_form.children().first()).prev()
    group_end_form.before(e) for e in repeatable_form.children()

    repeatable_preview = $("#repeatable_table_#{repeatable_id} tbody").clone()
    repeatable_preview.find('.form-group-index-cell').text(index+1)
    set_index_in_name(repeatable_preview.find('td.results-table-placeholder-cell'), index)

    $("#repeatable_group_end_preview_#{repeatable_id}").before(e) for e in repeatable_preview.clone().children()
    $("#repeatable_group_end_print_#{repeatable_id}").before(e) for e in repeatable_preview.children()

    body_padding = $('body').css('padding-top').replace('px', '')
    delay 10, -> 
      $(window).scrollTop(scroll_to_element.position().top-body_padding);

  $('#refresh-rois-btn').click ->
    $(this).button('loading')
    PharmTraceAPI.updateROIs()

  PharmTraceAPI.roisUpdated.connect ->
    #rois = jQuery.parseJSON('[{"id":1,"length":23.42,"name":"Length","seriesModality":"CT","seriesName":"Test Series 1","seriesUID":"1.2.3.4.5","sliceLocation":1,"studyName":"Test Study"},{"area":42.23,"id":23,"max":5,"mean":4.23,"min":3,"name":"Area","seriesModality":"MRT","seriesName":"Test Series 2","seriesUID":"5.4.3.2.1","sliceLocation":7,"studyName":"Test Study"},{"area":65,"id":42,"length":7,"max":23,"mean":7.4223,"min":-1,"name":"MegaROI","seriesModality":"PET","seriesName":"Test Series 2","seriesUID":"5.4.3.2.1","sliceLocation":23,"studyName":"Test Study"}]')
    rois = PharmTraceAPI.rois
    update_rois_table(rois)
        
    selects = $('.select-roi')

    update_roi_select(select) for select in selects
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