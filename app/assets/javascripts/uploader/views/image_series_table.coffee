@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ImageSeriesTable extends Backbone.View
  template: JST['uploader/templates/image_series_table']

  events:
    'change input#mark-all-for-upload': 'markForUpload'
    'change select.mass-assign-visit': 'massAssignVisit'

  initialize: ->
    @subviews = {}
    @listenTo @model.imageSeries, 'add', @appendImageSeries
    @listenTo @model.imageSeries, 'change:markedForUpload', @updateMarkForUpload

    @listenTo ImageUploader.app, 'change:patient', @updateVisitsSelectbox

  updateMarkForUpload: =>
    setTimeout =>
      marked = @model.imageSeries.where(markedForUpload: true).length
      @$('input#mark-all-for-upload').prop('checked', marked is @model.imageSeries.size())
    , 0

  markForUpload: (e) =>
    checked = $(e.currentTarget).prop('checked')
    for series in @model.imageSeries.models
      series.set markedForUpload: checked

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
    uid = series.get('instanceUid')
    index = @model.imageSeries.indexOf(series)
    @subviews[uid] = view = new ImageUploader.Views.ImageSeries
      model: series

    $previous = @$table.children().eq(index)
    if $previous.length > 0
      $previous.after(view.render().el)
    else
      @$table.append(view.render().el)

    massAssignVisitId = @$('select.mass-assign-visit').val()
    if massAssignVisitId?
      view.massAssignVisit
        id: massAssignVisitId
        text: @$('.mass-assign-visit').select2('data')[0].text
        visit: @visits[massAssignVisitId]
    @updateMarkForUpload()

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
