@value_at_path = (obj, path) ->
  return null unless obj?
  components = (component.replace(/\[/, "").replace(/\]/, "") for component in path.split("["))

  current_obj = obj
  for component in components
    component = parseInt(component, 10) if (/^[0-9]*$/.test(component))

    if current_obj[component]?
      current_obj = current_obj[component]
    else
      return null

  current_obj

@set_value_at_path = (obj, path, value) ->
  return false unless obj?
  components = (component.replace(/\[/, "").replace(/\]/, "") for component in path.split("["))

  current_obj = obj
  while components.length > 1
    component = components.shift()
    component = parseInt(component, 10) if (/^[0-9]*$/.test(component))

    if current_obj[component]?
      current_obj = current_obj[component]
    else
      return false

  last_component = components.shift()
  if current_obj[last_component]?
    current_obj[last_component] = value
    return true

  return false
