$ ->
  $('.initialize-select2').select2()

  $('body').on 'select2:open', (e) ->
    if $(e.target).parents('#sidebar').length
      $('.select2-container').addClass('select2--small')
