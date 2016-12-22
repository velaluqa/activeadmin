update_case_list = ->
  list_items = $('#case_list_sortable li')
  new_case_list = ($(item).attr('data-case-id') for item in list_items)

  $('#case_list').val(new_case_list.join(','))
  console.log($('#case_list').val())

$(document).ready ->
  $('#case_list_sortable').html_sortable().bind 'sortupdate', () ->
    update_case_list()
