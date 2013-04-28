$(document).ready ->
  $('#aq_patient_id').select2({
    multiple: true
    placeholder: 'Please select patients'
    allowClear: true
    data: { results: patients_select2_data }
    })