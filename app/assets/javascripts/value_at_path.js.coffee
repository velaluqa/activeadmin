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
