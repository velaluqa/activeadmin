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
    'click button.default': 'closeForm'

  initialize: ->
    @listenTo @model, 'change', @modelChanged

  closeForm: ->
    window.dashboard.unset('editWidget')

  saveWidget: ->
    if @model.isValid()
      window.dashboard.saveWidget(@model.validAttributes())
    else
      alert('Please make sure you specified all necessary values.')

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
    if key is 'resource_type'
      @updateGroupBy()

  modelChanged: =>
    @$('select#columns').select2(placeholder: 'All Columns')
    @renderTypeGroups()

  updateGroupBy: (initializing = false) ->
    type = @model.attributes.params?.resource_type
    if type?
      groupable = @RESOURCE_TYPES[type]?.groupable
      if groupable?
        @$('select#group_by').prop('disabled', false)
        @$('select#group_by').html('').select2
          data: [''].concat _.keys(groupable)
          minimumResultsForSearch: Infinity
          placeholder: 'Not grouped'
          allowClear: true
        if @rendering
          @$('select#group_by').val(@model.get('params').group_by).trigger('change')
        else
          @model.unset('group_by')
      else
        @$('select#group_by')
          .prop("disabled", true)
          .html('')
          .select2
            data: ['']
            placeholder: 'Not groupable'
            allowClear: false
        if @rendering
          @$('select#group_by').val(@model.get('params').group_by).trigger('change')
        else
          @model.unset('group_by')

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
    @$('#type').val(@model.get('type')).trigger('change')
    @rendering = true
    for key in ['resource_type']
      val = @model.get('params')[key]
      @$("##{key}").val(val).trigger('change') if val?
      @updateGroupBy()
    for key, val of (@model.attributes.params or {}) when not ['resource_type', 'group_by'].includes(key)
      @$("##{key}").val(val).trigger('change')
    @rendering = false
    this
