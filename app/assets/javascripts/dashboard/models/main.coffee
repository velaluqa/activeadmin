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

  newWidget: (row) ->
    @set editWidget: new Dashboard.Models.Widget(forRow: row)

  editWidget: (widget) ->
    @set editWidget: widget

  saveWidget: (attributes) ->
    widget = @get('editWidget')
    # Reset widget attributes
    widget.clear(silent: true)
    widget.set(attributes)
    # Add widget if it not already part of a row
    row = widget.forRow
    row.widgets.add(widget) if row?
    delete widget.forRow
    # Reset editWidget state
    @unset('editWidget')
    widget.report.load()
