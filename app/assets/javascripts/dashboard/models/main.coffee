@Dashboard ?= {}
@Dashboard.Models ?= {}
class Dashboard.Models.Main extends Backbone.Model
  url: ->
    '/admin/dashboard/save'

  constructor: (options) ->
    @rows = new Dashboard.Collections.Rows(options.config.rows)
    delete options.config
    @reportableStudies = options.reportableStudies
    delete options.reportableStudies
    super

  initialize: (options = {}) ->
    @on 'change:editing', @saveDashboardConfiguration

  defaults:
    editing: false

  saveDashboardConfiguration: (_, editing) =>
    return if editing
    removables = []
    for row in @rows.models when row.widgets.isEmpty()
      removables.push(row)
    @rows.remove(removables)
    @save()

  toJSON: ->
    return config:
      rows: @rows.toJSON()

  addEmptyRow: ->
    @rows.add(new Dashboard.Models.Row(widgets: []))
