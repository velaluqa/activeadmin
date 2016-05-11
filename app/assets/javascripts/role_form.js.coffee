$(document).ready ->
  $('.activity input[data-activity=manage]').on 'change', (e) ->
    $target = $(e.target)
    subject = $target.data('subject')
    if $target.prop('checked')
      $(".permission.#{subject} input").each (i, checkbox) ->
        $checkbox = $(checkbox)
        unless $checkbox.data('activity') is 'manage'
          $checkbox.prop(checked: true, disabled: true)
    else
      $(".permission.#{subject} input").each (i, checkbox) ->
        $checkbox = $(checkbox)
        unless $checkbox.data('activity') is 'manage'
          $checkbox.prop(checked: false, disabled: false)
