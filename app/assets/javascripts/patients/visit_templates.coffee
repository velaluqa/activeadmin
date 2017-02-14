#= require hamlcoffee
#= require_tree .
#= require_self

select_template = JST['patients/visit_template_select']
preview_template = JST['patients/visit_template_preview']
selected_study = null
visit_templates = null
preselect = null

renderVisitTemplateSelect = (templates) ->
  visit_templates = templates
  enforce = _.findKey(visit_templates, (tpl) -> tpl.create_patient_enforce)
  if enforce?
    $('#visit_template_select').html('')
    renderVisitTemplatePreview(enforce)
  else
    options = for key, tpl of visit_templates when not tpl.hide_on_create_patient
      { id: key, text: (tpl.label or key) }
    preselect ?= _.findKey(visit_templates, (tpl) -> tpl.create_patient_default)
    $('#visit_template_select').html select_template
      options: options
      preselect: preselect
      selected_center: $('#patient_center_id').val()
      selected_study: selected_study
    $('#patient_visit_template').select2
      placeholder: 'Do not create any visits'
      allowClear: true
      disabled: false
    renderVisitTemplatePreview(preselect or '')
    $('#patient_visit_template').on 'change', (e) ->
      renderVisitTemplatePreview($(e.currentTarget).val())

renderVisitTemplatePreview = (template = '') ->
  return $('#visit_template_preview').html('') if template is ''
  visits = visit_templates?[template]?['visits'] or []
  $('#visit_template_preview').html preview_template
    visits: visits

window.visitTemplatesForm = (options = {}) ->
  selected_study = options.selected_study
  visit_templates = options.visit_templates
  preselect = options.preselect

  # All possible templates are already loaded if study selected
  unless selected_study?
    $('#patient_center_id').on 'change', (e) ->
      $.ajax
        url: '/admin/patients/visit_templates.json',
        data:
          center_id: $('#patient_center_id').val()
      .done (templates) ->
        preselect = null
        renderVisitTemplateSelect(templates)

  renderVisitTemplateSelect(visit_templates)
