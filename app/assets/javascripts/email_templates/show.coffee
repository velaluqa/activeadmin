$ ->
  editor = ace.edit('editor')
  editor.setTheme('ace/theme/monokai')
  editor.session.setMode('ace/mode/liquid')
  editor.commands.commmandKeyBinding = {}
  editor.setOptions
    readOnly: true
    highlightActiveLine: false
    highlightGutterLine: false

  initializeRecordSearch($('#preview-resource'))

  refreshPreview = ->
    success = (response) ->
      window.srcDoc.set($('#preview')[0], response.result)
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
