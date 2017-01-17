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
