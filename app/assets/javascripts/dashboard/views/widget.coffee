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
    switch model.type
      when 'overview' then @renderOverview(model)
      when 'historic_count' then @renderHistoricCount(model)

  renderOverview: (model) ->
    return unless model.get('studies')?
    @$('h3').html('Overview')
    @$('.content').attr(class: 'content table')
    @$('.content').html(@overviewTemplate(report: model.toJSON()))

  renderHistoricCount: (model) ->
    return unless model.get('datasets')?
    @$('h3').html(model.title())
    @$('.content').attr(class: 'content graph')
    $canvas = $('<canvas></canvas>', attr: { width: '100%', height: '100%' })
    @$('.content').html($canvas)
    ctx = $canvas[0].getContext('2d')
    chart = new Chart ctx,
      type: 'line'
      data:
        datasets: @transformDataSets(model.get('datasets'))
      options:
        maintainAspectRatio: false
        legend:
          position: 'bottom'
        scales:
          yAxes: [
            ticks:
              min: 0
          ]
          xAxes: [
            type: 'time'
            time:
              displayFormats:
                hour: 'hh:mm'
                minute: 'hh:mm'
                second: 'hh:mm'
                quarter: 'MMM YYYY'
          ]

  transformDataSets: (datasets) ->
    for dataset in datasets
      {
        label: dataset.label
        tension: 0
        steppedLine: true
        data: dataset.data
      }

  render: =>
    @$el.html(@template())
    @renderLoading()
    @renderReport(@model.report, null) if @model.report?
    this
