update_visits = ->
  list_items = $('#visits_sortable li')
  new_visits_list = ($(item).attr('data-visit-id') for item in list_items)

  $('#new_visits_list').val(new_visits_list.join(','))

$(document).ready ->
  $('#visits_sortable').html_sortable().bind 'sortupdate', () ->
    update_visits()
