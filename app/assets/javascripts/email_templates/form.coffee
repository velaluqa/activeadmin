$ ->
  editor = ace.edit('editor')
  editor.setValue($('#email_template_template').val())
  editor.setTheme('ace/theme/monokai')
  editor.session.setMode('ace/mode/html_ruby')
  editor.getSession().on 'change', (e) ->
    $('#email_template_template').val(editor.getValue())

  $('#preview-resource').select2
    placeholder: 'Please select a resource'
    allowClear: false
    minimumInputLength: 3
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
