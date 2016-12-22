@Dashboard ?= {}
@Dashboard.Models ?= {}
class Dashboard.Models.Widget extends Backbone.Model
  initialize: ->
    @report = new Dashboard.Models.Report
      type: @attributes.type
      params: @attributes.params
    @report.load()
