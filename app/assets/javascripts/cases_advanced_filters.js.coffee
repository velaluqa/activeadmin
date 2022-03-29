hide_fake_sidebar_entry = ->
  $('#advanced_filter_data_sidebar_section').hide()

replace_stock_patient_filter = ->
  $('#q_patient_id').replaceWith('<input id="q_patient_id" type="hidden" name="q[patient_id_in][]" style="width: 100%"/>')

$(document).ready ->
  return unless $('body').hasClass('admin_cases')
  hide_fake_sidebar_entry()

  replace_stock_patient_filter()
  
  $('#q_patient_id').select2({
    multiple: true
    placeholder: 'Please select patients'
    allowClear: true
    data: patients_select2_data
    initSelection: (element, callback) ->
      values = element.val().split(',')
      selection = ({id: value, text: patients_options_map[value]} for value in values when patients_options_map[value]?)

      callback(selection)
    })

  $('#q_patient_id').select2('val', selected_patients)
