$ ->
  editor = ace.edit('editor')
  editor.setValue($('#email_template_template').val())
  editor.setTheme('ace/theme/monokai')
  editor.session.setMode('ace/mode/html_ruby')
  editor.getSession().on 'change', (e) ->
    $('#email_template_template').val(editor.getValue())
