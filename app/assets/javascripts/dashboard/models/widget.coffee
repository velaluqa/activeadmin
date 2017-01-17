@Dashboard ?= {}
@Dashboard.Models ?= {}
class Dashboard.Models.Widget extends Backbone.Model
  defaults:
    type: 'overview'
    params:
      display: 'line'
      resolution: 'day'

  constructor: (options) ->
    @forRow = options.forRow
    delete options.forRow
    super

  initialize: ->
    @report = new Dashboard.Models.Report(widget: this)
    @load() if @collection?

  load: -> @report.load()

  validAttributes: ->
    type = @get('type')
    if type is 'overview'
      {
        type: type,
        params: _.pick(@get('params'), 'columns', 'exclude_studies')
      }
    else if type is 'historic_count'
      {
        type: type,
        params: _.pick(@get('params'), 'study_id', 'resource_type', 'group_by', 'display', 'resolution')
      }

  isValid: ->
    type = @get('type')
    console.log @, @attributes
    if type is 'historic_count'
      return false unless _.keys(@get('params')).includes('study_id', 'resource_type', 'display', 'resolution')
    true
