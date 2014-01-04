$(document).ready ->
  dicom_value_tqc_selects = (select for select in $('select') when (select.id.slice(0, 11) == 'tqc_result_') and $(select).hasClass('dicom_value_tqc'))

  $('#tqc_form').submit ->
    for select in dicom_value_tqc_selects
      dicom_check_result = $('#result_'+select.id).val()
      console.log(dicom_check_result)
      if $(select).val() != dicom_check_result and $('#tqc_comment').val().length == 0
        $('#tqc_comment_label, #tqc_comment_hint').css('color', 'red')
        return false
    
    return true
    