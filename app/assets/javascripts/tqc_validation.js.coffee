$(document).ready ->
  tqc_selects = (select for select in $('select') when select.id.slice(0, 11) == 'tqc_result_')

  $('#tqc_form').submit ->
    for select in tqc_selects
      if $(select).val() != '1' and $('#tqc_comment').val().length == 0
        $('#tqc_comment_label, #tqc_comment_hint').css('color', 'red')
        return false
    
    return true
    