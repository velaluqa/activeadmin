@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ImageSeries extends Backbone.View
  template: JST['uploader/templates/image_series']
  warningsListTemplate: JST['uploader/templates/warnings_list']

  tagName: 'tbody'
  className: 'image-series'

  events:
    'click .select2': 'stopPropagation'
    'click td.warnings': 'stopPropagation'
    'click .upload-flag': 'stopPropagation'
    'change .upload-flag input': 'markForUpload'
    'change select.visit': 'changeAssignedVisit'
    'change select.required-series': 'changeAssignedRequiredSeries'
    'click tr.image-series': 'toggleShowImages'

  initialize: ->
    # Visits need to be saved temporarily so we can access the visit
    # id and respective required series options.
    @visits = {}

    @listenTo @model, 'change:imageCount', @updateImageCount
    @listenTo @model, 'change:showImages', @showHideImages
    @listenTo @model, 'change:seriesDateTime', @updateDateTime
    @listenTo @model, 'change:imageCount change:uploadState change:uploadProgress', @updateUploadState
    @listenTo @model, 'change:assignVisitId', @renderRequiredSeriesSelectbox
    @listenTo @model, 'change:markedForUpload', @renderMarkForUpload
    @listenTo @model, 'warnings', @renderWarnings

    @listenTo ImageUploader.app, 'change:patient', @renderVisitsSelectbox

  updateImageCount: ->
    @$('.image-count').html(@model.get('imageCount'))

  updateDateTime: =>
    @$('.datetime').html(@model.get('seriesDateTime'))

  updateUploadState: =>
    state = @model.get('uploadState')
    progress = @model.get('uploadProgress')
    @$('.upload-state .progress-bar').toggleClass('parsed', state is 'parsed')
    @$('.upload-state .progress-bar').toggleClass('uploading', state is 'uploading')
    @$('.upload-state .progress-bar').toggleClass('uploaded', state is 'uploaded')
    @$('.upload-state .progress').css width: "#{progress}%"
    @$('.upload-state .label').html(@model.getUploadStateLabel())

  stopPropagation: (e) ->
    e.stopPropagation()

  toggleShowImages: (e) =>
    return if $(e.target).hasClass('hasDatepicker')
    @model.set(showImages: not @model.get('showImages'))

  markForUpload: (e) =>
    e.stopPropagation()
    marked = @model.get('markedForUpload')
    @model.set markedForUpload: not marked

  changeAssignedVisit: (e) ->
    visitId = $(e.currentTarget).val()
    patientId = ImageUploader.app.get('patient')?.id
    switch visitId
      when 'create'
        window.open("/admin/visits/new?patient_id=#{patientId}", 'Create Visit')
        @$('select.visit').val('').trigger('change')
      when ''
        @model.set assignVisitId: null
      else
        @model.set assignVisitId: parseInt(visitId, 10)

  changeAssignedRequiredSeries: (e) ->
    values = $(e.currentTarget).val()
    @model.set assignRequiredSeries: values

  showHideImages: =>
    @$el.toggleClass('show-images', @model.get('showImages') is true)

  renderMarkForUpload: =>
    marked = @model.get('markedForUpload')
    @$('tr.image-series').toggleClass('marked-for-upload', marked)
    @renderVisitsSelectbox()

  renderVisitsSelectbox: =>
    markedForUpload = @model.get('markedForUpload')
    patientId = ImageUploader.app.get('patient')?.id
    if patientId? and markedForUpload
      @$('select.visit').select2
        placeholder: 'No visit assigned'
        allowClear: true
        ajax:
          cache: true
          url: "/v1/patients/#{patientId}/visits.json"
          processResults: (data, params) =>
            @visits = {}
            results = [{ id: 'create', text: 'Create New Visit' }]
            results = results.concat _.map data, (visit) =>
              @visits[visit.id] = visit
              {
                id: visit.id
                text: "#{visit.visit_number} — #{visit.visit_type}"
              }
            return { results: results }
      @$('select.visit')
        .prop('disabled', false)
        .val('')
        .trigger('change')
    else
      @$('select.visit')
        .prop('disabled', true)
        .val('')
        .trigger('change')
        .select2
          placeholder: 'No visit assigned'
          allowClear: true

  renderRequiredSeriesSelectbox: =>
    visitId = @model.get('assignVisitId')
    options =
      placeholder: 'No required series assigned'
      data: @visits[visitId]?.required_series or []
    if @model.get('assignVisitId')?
      @$('select.required-series').prop('disabled', false).select2(options)
    else
      @$('select.required-series').val([]).trigger('change')
      @$('select.required-series').prop('disabled', true).select2(options)

  renderWarnings: =>
    @$('tr.image-series').toggleClass('has-warnings', @model.hasWarnings())

  render: =>
    @$el.html @template
      name: @model.get('name')
      imageCount: @model.get('imageCount')
      seriesDateTime: @model.get('seriesDateTime')

    @$('tr.image-series > td.warnings > a[data-toggle=popover]').popover
      placement: 'left'
      html: true
      content: =>
        @warningsListTemplate(warnings: @model.formatWarnings())

    @updateUploadState()

    @renderVisitsSelectbox()
    @renderRequiredSeriesSelectbox()

    images = new ImageUploader.Views.Images
      el: @$('tr.images td')
      collection: @model.images
    images.render()

    this
