$(document).ready ->
  mqc_selects = (select for select in $('select') when select.id.slice(0, 11) == 'mqc_result_')

  $('#mqc_form').submit ->
    for select in mqc_selects
      if $(select).val() != '1' and $('#mqc_comment').val().length == 0
        $('#mqc_comment_label, #mqc_comment_hint').css('color', 'red')
        return false
    
    return true
    