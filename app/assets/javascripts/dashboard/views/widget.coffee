@Dashboard ?= {}
@Dashboard.Views ?= {}
class Dashboard.Views.Widget extends Backbone.View
  className: 'widget'
  template: JST['dashboard/templates/widget']
  overviewTemplate: JST['dashboard/templates/widget_overview']

  initialize: ->
    @model.report.on 'change', @renderReport

  renderReport: (model, value) =>
    @$('.content').html(@overviewTemplate(report: model.toJSON()))

  render: =>
    @$el.html(@template())
    console.log @model.report
    @renderReport(@model.report, null) if @model.report?
    this
