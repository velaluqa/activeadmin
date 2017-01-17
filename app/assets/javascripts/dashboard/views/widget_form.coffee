@Dashboard ?= {}
@Dashboard.Views ?= {}
class Dashboard.Views.WidgetForm extends Backbone.View
  template: JST['dashboard/templates/widget_form']

  RESOURCE_TYPES:
    Patient: {}
    Visit:
      groupable:
        state: true
        mqc_state: true
    ImageSeries:
      groupable:
        state: true
    RequiredSeries:
      groupable:
        tqc_state: true

  events:
    'change select': 'updateFromSelect'
    'click button.primary': 'saveWidget'

  initialize: ->
    @listenTo @model, 'change', @modelChanged

  saveWidget: ->
    window.dashboard.saveWidget()

  updateFromSelect: (e) =>
    $select = $(e.currentTarget)
    key = $select.attr('name')
    val = $select.val()
    if key is 'type'
      @model.set(key, val)
    else
      params = _.clone(@model.get('params'))
      params[key] = val
      @model.set(params: params)

  modelChanged: (model) =>
    @$('select#columns').select2(placeholder: 'All Columns')
    @renderTypeGroups()
    type = model.changed.params?.resource_type
    prev_type = model.previousAttributes().params?.resource_type
    if type? and prev_type isnt type
      groupable = @RESOURCE_TYPES[type]?.groupable
      if groupable?
        @model.unset('group_by')
        @$('select#group_by').prop('disabled', false)
        @$('select#group_by').html('').select2
          data: [''].concat _.keys(groupable)
          minimumResultsForSearch: Infinity
          placeholder: 'Not grouped'
          allowClear: true
      else
        @model.unset('group_by')
        @$('select#group_by')
          .prop("disabled", true)
          .html('')
          .select2
            data: ['']
            placeholder: 'Not groupable'
            allowClear: false

  renderTypeGroups: ->
    type = @model.get('type')
    @$(".type-group:not([data-for-type=#{type}])").css('display', 'none')
    @$(".type-group[data-for-type=#{type}]").css('display', 'block')

  render: =>
    @$('.modal-body').html(@template())
    @$('select').select2
      minimumResultsForSearch: Infinity
      placeholder: 'Select'
      allowClear: false
    @renderTypeGroups()
    @$('#study_id, #exclude_studies').select2
      data: for study in window.dashboard.reportableStudies
        { id: study.id, text: study.name }
      placeholder: 'Select Study'
    this
