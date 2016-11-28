$ ->
  editor = ace.edit('editor')
  editor.setTheme('ace/theme/monokai')
  editor.session.setMode('ace/mode/liquid')
  editor.commands.commmandKeyBinding = {}
  editor.setOptions
    readOnly: true
    highlightActiveLine: false
    highlightGutterLine: false

  $('#preview-resource').select2
    placeholder: 'Please select a resource'
    allowClear: false
    minimumInputLength: 2
    ajax:
      url: '/v1/search'
      dataType: 'json'
      delay: 250
      data: (params) -> { query: params.term }
      processResults: (results, params) ->
        groups = ['Study', 'Center', 'Patient', 'Visit', 'ImageSeries', 'Image', 'BackgroundJob']
        grouped = _
          .chain(results)
          .map (obj) ->
            obj.id = "#{obj.result_type}_#{obj.result_id}"
            obj
          .groupBy (obj) -> obj.result_type
          .value()
        return {
          results: for group in groups when grouped[group]?
            { text: group, children: grouped[group] }
        }
      cache: false
    templateResults: (item) ->
      return "#{item.result_type}: #{item.text}"

  refreshPreview = ->
    success = (response) ->
      $('#preview')[0].srcdoc = response.result
      editor.session.setAnnotations([])
      $('.iframe-wrapper').toggleClass('loading', false)

    failure = (response) ->
      annotations = for error in response.responseJSON.errors
        row: (error.line_number - 1)
        column: 0
        text: error.message
        type: 'error'
      editor.session.setAnnotations(annotations)
      $('.iframe-wrapper').toggleClass('loading', false)

    options =
      data:
        type: $('#email_template_email_type').val()
        subject: $('#preview-resource').val()
        template: editor.getValue()
    $.ajax('/admin/email_templates/preview', options).then(success).fail(failure)

  timeout = null
  schedulePreviewRefresh = ->
    $('.iframe-wrapper').toggleClass('loading', true)
    refreshPreview()

  $('#preview-resource').on('change', schedulePreviewRefresh)
