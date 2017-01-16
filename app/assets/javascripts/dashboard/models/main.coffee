@Dashboard ?= {}
@Dashboard.Models ?= {}
class Dashboard.Models.Main extends Backbone.Model
  initialize: (options = {}) ->
    @rows = new Dashboard.Collections.Rows(options.config.rows)
    @on 'change:editing', @saveDashboardConfiguration

  defaults:
    editing: false

  saveDashboardConfiguration: (_, editing) =>
    return if editing
    for row in @rows.models
      @rows.remove(row) if row.isEmpty()

  addEmptyRow: ->
    @rows.add(new Dashboard.Models.Row(widgets: []))
