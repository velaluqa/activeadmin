@Dashboard ?= {}
@Dashboard.Views ?= {}
class Dashboard.Views.Widget extends Backbone.View
  className: 'widget'
  template: JST['dashboard/templates/widget']
  overviewTemplate: JST['dashboard/templates/widget_overview']

  initialize: ->
    @model.report.on 'change', @renderReport
    @model.report.on 'fetching fetched', @renderLoading

  renderLoading: =>
    @$el.toggleClass('loading', @model.report.isFetching)

  renderReport: (model, value) =>
    @$('.content').html(@overviewTemplate(report: model.toJSON()))

  render: =>
    @$el.html(@template())
    @renderReport(@model.report, null) if @model.report?
    @renderLoading()
    this
