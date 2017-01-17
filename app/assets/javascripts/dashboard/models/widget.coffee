@Dashboard ?= {}
@Dashboard.Models ?= {}
class Dashboard.Models.Widget extends Backbone.Model
  initialize: ->
    @report = new Dashboard.Models.Report(widget: this)
    @load() if @collection?

  load: -> @report.load()
