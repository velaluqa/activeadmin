@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ImageSeries extends Backbone.View
  template: JST['uploader/templates/image_series']
  tagName: 'tbody'
  className: 'image-series'

  events:
    'click .select2': 'stopPropagation'
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
    @listenTo @model, 'change:visit_id', @renderRequiredSeriesSelectbox

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

  changeAssignedVisit: (e) ->
    visitId = $(e.currentTarget).val()
    patientId = ImageUploader.app.get('patient')?.id
    switch visitId
      when 'create'
        window.open("/admin/visits/new?patient_id=#{patientId}", 'Create Visit')
        @$('select.visit').val('').trigger('change')
      when ''
        @model.set visit_id: null
      else
        @model.set visit_id: visitId

  changeAssignedRequiredSeries: ->
    console.log 'required series changed', arguments

  showHideImages: =>
    @$el.toggleClass('show-images', @model.get('showImages') is true)

  renderVisitsSelectbox: =>
    patientId = ImageUploader.app.get('patient')?.id
    if patientId?
      @$('select.visit').select2
        # placeholder: 'No visit assigned'
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
      @$('select.visit').val('').trigger('change')
    else
      @$('select.visit').select2
        placeholder: 'No visit assigned'
        allowClear: true

  renderRequiredSeriesSelectbox: =>
    visitId = @model.get('visit_id')
    options =
      placeholder: 'No required series assigned'
      data: @visits[visitId]?.required_series or []
    @$requiredSeriesSelect ?= @$('select.required-series').select2(options)
    if @model.get('visit_id')?
      @$('select.required-series').prop('disabled', false).select2(options)
    else
      @$('select.required-series').val([]).trigger('change')
      @$('select.required-series').prop('disabled', true).select2(options)

  render: =>
    @$el.html @template
      name: @model.get('name')
      imageCount: @model.get('imageCount')
      seriesDateTime: @model.get('seriesDateTime')

    @updateUploadState()

    @renderVisitsSelectbox()
    @renderRequiredSeriesSelectbox()

    images = new ImageUploader.Views.Images
      el: @$('tr.images td')
      collection: @model.images
    images.render()

    this
