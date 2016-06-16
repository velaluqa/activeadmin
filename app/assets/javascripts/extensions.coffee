String.prototype.paddingLeft = (paddingValue) ->
  "#{paddingValue}#{this}"[-paddingValue.length..-1]

String.prototype.paddingRight = (paddingValue) ->
  "#{this}#{paddingValue}"[0..paddingValue.length - 1]
