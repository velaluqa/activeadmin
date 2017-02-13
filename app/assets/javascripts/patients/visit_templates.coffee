#= require hamlcoffee
#= require_tree .
#= require_self

preview_template = JST['patients/visit_template_preview']
selected_study = null
visit_templates = null

renderVisitTemplates = (templates, options = {}) ->
  visit_templates = templates
  if visit_templates?
    if options.withoutData
      $('#patient_visit_template').select2
        placeholder: 'Do not create any visits'
        allowClear: true
        disabled: false
    else
      data = for key, tpl of visit_templates
        { id: key, text: (tpl.label or key) }
      $('#patient_visit_template').html('<option></option>').select2
        placeholder: 'Do not create any visits'
        allowClear: true
        disabled: false
        data: data
  else
    if not selected_study? and $('#patient_center_id').val() is ''
      $('#patient_visit_template').html('').select2
        placeholder: 'Please choose a center first'
        disabled: true
    else
      $('#patient_visit_template').html('').select2
        placeholder: 'No template available'
        disabled: true

renderVisitTemplatePreview = (template = '') ->
  return $('#visit_template_preview').html('') if template is ''
 
  visits = visit_templates?[template]?['visits'] or []
  $('#visit_template_preview').html(preview_template(visits: visits))

window.visitTemplatesForm = (options = {}) ->
  selected_study = options.selected_study
  visit_templates = options.visit_templates

  # All possible templates are already loaded if study selected
  unless study_selected?
    $('#patient_center_id').on 'change', (e) ->
      $.ajax
        url: '/admin/patients/visit_templates.json',
        data:
          center_id: $('#patient_center_id').val()
      .done (templates) ->
        renderVisitTemplates(templates)
        renderVisitTemplatePreview('')

  renderVisitTemplates(visit_templates, withoutData: true)
  renderVisitTemplatePreview($('#patient_visit_template').val())

  $('#patient_visit_template').on 'change', (e) ->
    renderVisitTemplatePreview($(e.currentTarget).val())
