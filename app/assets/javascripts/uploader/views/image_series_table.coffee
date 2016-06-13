@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ImageSeriesTable extends Backbone.View
  template: JST['uploader/templates/image_series_table']

  events:
    'change select.mass-assign-visit': 'massAssignVisit'

  initialize: ->
    @subviews = {}
    @listenTo @model.imageSeries, 'add', @appendImageSeries

    @listenTo ImageUploader.app, 'change:patient', @updateVisitsSelectbox

  massAssignVisit: (e) =>
    visitId = $(e.currentTarget).val()
    patientId = ImageUploader.app.get('patient')?.id
    if visitId is 'create'
      window.open("/admin/visits/new?patient_id=#{patientId}", 'Create Visit')
      @$('select.visit').val('').trigger('change')
      return

    seriesWithVisitAssignment = @model.imageSeries.filter (series) -> series.get('assignVisitId')?
    if seriesWithVisitAssignment.length
      return unless confirm('Do you really want to overwrite the current visit assignment?')

    if visitId?
      for _, view of @subviews
        view.massAssignVisit
          id: visitId
          text: @$('.mass-assign-visit').select2('data')[0].text
          visit: @visits[visitId]
    else
      for _, view of @subviews
        view.massAssignVisit id: visitId

  appendImageSeries: (series) =>
    name = series.get('name')
    @subviews[name] = view = new ImageUploader.Views.ImageSeries
      model: series
    @$table.append(view.render().el)
    massAssignVisitId = @$('select.mass-assign-visit').val()
    if massAssignVisitId?
      view.massAssignVisit
        id: massAssignVisitId
        text: @$('.mass-assign-visit').select2('data')[0].text
        visit: @visits[massAssignVisitId]

  updateVisitsSelectbox: =>
    @$('select.mass-assign-visit')
      .val('')
      .trigger('change')

  renderVisitsSelectbox: ->
    @$('select.mass-assign-visit').select2
      placeholder: 'Mass-assign visit'
      allowClear: true
      ajax:
        cache: true
        url: ->
          "/v1/patients/#{ImageUploader.app.get('patient')?.id}/visits.json"
        processResults: (data, params) =>
          @visits = {}
          results = [{ id: 'create', text: 'Create New Visit' }]
          results = results.concat _.map data, (visit) =>
            @visits[visit.id] = visit
            {
              id: visit.id
              text: "#{visit.visit_number} — #{visit.visit_type or 'no visit type'}"
            }
          return { results: results }

  render: =>
    @$el.html(@template())
    @$table = @$('table')

    @model.imageSeries.each @appendImageSeries

    @renderVisitsSelectbox()

    this
