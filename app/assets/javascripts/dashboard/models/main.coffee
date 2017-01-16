@Dashboard ?= {}
@Dashboard.Models ?= {}
class Dashboard.Models.Main extends Backbone.Model
  url: ->
    '/admin/dashboard/save'

  initialize: (options = {}) ->
    @rows = new Dashboard.Collections.Rows(options.config.rows)
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
