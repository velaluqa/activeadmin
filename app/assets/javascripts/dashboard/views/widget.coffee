@Dashboard ?= {}
@Dashboard.Views ?= {}
class Dashboard.Views.Widget extends Backbone.View
  className: 'widget'
  template: JST['dashboard/templates/widget']
  overviewTemplate: JST['dashboard/templates/widget_overview']

  events:
    'click .buttons i.fa-edit': 'editWidget'
    'click .buttons i.fa-trash-o': 'removeWidget'

  initialize: ->
    @model.report.on 'change', @renderReport
    @model.report.on 'fetching fetched', @renderLoading

  editWidget: =>
    window.dashboard.editWidget(@model)

  removeWidget: =>
    return unless confirm('Do you really want to remove this widget?')
    @model.collection.remove(@model)

  renderLoading: =>
    @$el.toggleClass('loading', @model.report.isFetching)

  renderReport: (model, value) =>
    switch model.type()
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
        datasets: @transformDataSets(
          model.get('datasets'),
          model.widget.get('params').resource_type,
          model.widget.get('params').group_by
        )
      options:
        maintainAspectRatio: false
        legend:
          display: model.get('datasets').length > 1
          position: 'bottom'
        scales:
          yAxes: [
            ticks:
              min: 0
          ]
          xAxes: [
            type: 'time'
            time:
              unit: model.widget.get('params').resolution
              displayFormats:
                year: 'YYYY'
                quarter: '[Q]Q.YYYY'
                month: 'MMM YYYY'
                week: 'ww gggg'
                day: 'DD.MM.YYYY'
                hour: 'DD.MM.YYYY HH:mm'
                minute: 'DD.MM.YYYY HH:mm'
                second: 'DD.MM.YYYY HH:mm:ss'
            ticks:
              autoSkip: true
              maxTicksLimit: 6
          ]

  transformDataSets: (datasets, resourceType, groupBy) ->
    for dataset in datasets
      background = @colorMapping[resourceType]?[groupBy]?[dataset.label]?.background or @colorMapping[resourceType]?.default.background
      foreground = @colorMapping[resourceType]?[groupBy]?[dataset.label]?.foreground or @colorMapping[resourceType]?.default.foreground
      {
        label: dataset.label
        tension: 0
        # steppedLine: true
        data: dataset.data
        backgroundColor: background
        borderColor: foreground
        pointBorderColor: foreground
        pointBackgroundColor: foreground
        spanGaps: true
      }

  render: =>
    @$el.html(@template())
    @renderLoading()
    @renderReport(@model.report, null) if @model.report?
    this

  colorMapping:
    Patient:
      default:
        foreground: '#34495e'
        background: 'rgba(52, 73, 94, 0.2)'
    Visit:
      default:
        foreground: '#34495e'
        background: 'rgba(52, 73, 94, 0.2)'
      state:
        incomplete_na:
          foreground: '#7f8c8d'
          background: 'rgba(127, 140, 141, 0.2)'
        incomplete_queried:
          foreground: '#9b59b6'
          background: 'rgba(155, 89, 182, 0.2)'
        complete_tqc_pending:
          foreground: '#3498db'
          background: 'rgba(52, 152, 219, 0.2)'
        complete_tqc_issues:
          foreground: '#c0392b'
          background: 'rgba(192, 57, 43, 0.2)'
        complete_tqc_passed:
          foreground: '#218b4a'
          background: 'rgba(33, 139, 74, 0.2)'
      mqc_state:
        pending:
          foreground: '#3498db'
          background: 'rgba(52, 152, 219, 0.2)'
        issues:
          foreground: '#c0392b'
          background: 'rgba(192, 57, 43, 0.2)'
        passed:
          foreground: '#218b4a'
          background: 'rgba(33, 139, 74, 0.2)'
    ImageSeries:
      default:
        foreground: '#34495e'
        background: 'rgba(52, 73, 94, 0.2)'
      state:
        importing:
          foreground: '#7f8c8d'
          background: 'rgba(127, 140, 141, 0.2)'
        imported:
          foreground: '#c0392b'
          background: 'rgba(192, 57, 43, 0.2)'
        visit_assigned:
          foreground: '#e6822a'
          background: 'rgba(230, 130, 42, 0.2)'
        required_series_assigned:
          foreground: '#27ae60'
          background: 'rgba(39, 174, 96, 0.2)'
        not_required:
          foreground: '#3498db'
          background: 'rgba(52, 152, 219, 0.2)'
    RequiredSeries:
      default:
        foreground: '#34495e'
        background: 'rgba(52, 73, 94, 0.2)'
      tqc_state:
        pending:
          foreground: '#3498db'
          background: 'rgba(52, 152, 219, 0.2)'
        issues:
          foreground: '#c0392b'
          background: 'rgba(192, 57, 43, 0.2)'
        passed:
          foreground: '#218b4a'
          background: 'rgba(33, 139, 74, 0.2)'
