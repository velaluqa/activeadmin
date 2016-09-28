editor = null
loadEditor = ->
  triggeringResource = $('#notification_profile_triggering_resource').val()
  if triggeringResource == ''
    $('#filters-jsoneditor').html("Please choose a triggering resource above.")
  else
    if editor?
      editor.destroy()
      editor = null
    $('#filters-jsoneditor').html('Loading ...')
    $.ajax
      url: "http://localhost:3000/admin/notification_profiles/filters_schema?triggering_resource=#{triggeringResource}"
      success: (schema) ->
        $('#filters-jsoneditor').html('')
        editor = new JSONEditor document.getElementById('filters-jsoneditor'),
          ajax: true
          schema: schema
          disable_collapse: true
          disable_edit_json: true
          disable_properties: true
          disable_array_reorder: true
          form_name_root: 'filters'
          no_additional_properties: true
      error: (response, status, message) ->
        $('#filters-jsoneditor').html(response.responseJSON?.error || message)

$ ->
  $('#notification_profile_triggering_resource').on 'change', loadEditor
  loadEditor()
