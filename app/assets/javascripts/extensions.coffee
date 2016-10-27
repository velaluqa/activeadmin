String.prototype.paddingLeft = (paddingValue) ->
  "#{paddingValue}#{this}"[-paddingValue.length..-1]

String.prototype.paddingRight = (paddingValue) ->
  "#{this}#{paddingValue}"[0..paddingValue.length - 1]

String.prototype.capitalize = ->
  this[0].toUpperCase() + this[1..-1].toLowerCase()

if typeof String.prototype.endsWith isnt 'function'
  String.prototype.endsWith = (suffix) ->
    @indexOf(suffix, @length - suffix.length) isnt -1

Array.ensureArray = (val) ->
  if toString.call(val) is '[object Array]'
    _.compact(val)
  else
    _.compact([val])
