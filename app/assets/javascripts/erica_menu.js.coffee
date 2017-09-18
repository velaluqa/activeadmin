toggleMenu = (isPinned) ->
  $('input#toggle-menu').attr('checked', isPinned)
  if isPinned
    widths = $('.header-item.tabs li a').map(-> $(this).outerWidth()).get()
    width = Math.max.apply(Math, widths);
    $('body')
      .toggleClass('pin-menu', true)
      .css(padding: "53px 0 0 #{width}px")
    $('#title_bar')
      .css('padding-left': "#{width}px")
  else
    $('body')
      .toggleClass('pin-menu', false)
      .removeAttr('style')
    $('#title_bar').removeAttr('style')

$ ->
  console.log(localStorage.isEricaMenuPinned)
  localStorage.isEricaMenuPinned ||= false
  toggleMenu(localStorage.isEricaMenuPinned == 'true')

  $('#toggle-menu').on 'change', (e) ->
    isChecked = $(e.target).is(':checked')
    localStorage.isEricaMenuPinned = isChecked
    toggleMenu(isChecked)
