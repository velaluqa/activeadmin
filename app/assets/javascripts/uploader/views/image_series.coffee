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
    'click tr.image-series': 'clickImageSeries'

  initialize: ->
    # Visits need to be saved temporarily so we can access the visit
    # id and respective required series options.
    @visits = {}

    @listenTo @model, 'change:imageCount', @updateImageCount
    @listenTo @model, 'change:showImages', @showHideImages
    @listenTo @model, 'change:seriesDateTime', @updateDateTime
    @listenTo @model, 'change:imageCount change:uploadState change:uploadProgress', @updateUploadState
    @listenTo @model, 'change:assignVisitId', @updateRequiredSeriesSelectbox
    @listenTo @model, 'change:markedForUpload', @updateVisitsSelectbox
    @listenTo @model, 'change:markedForUpload', @updateRequiredSeriesSelectbox
    @listenTo @model, 'change:markedForUpload', @renderMarkForUpload
    @listenTo @model, 'warnings', @renderWarnings
    @listenTo @model, 'change:disabled', @renderDisabled

    @listenTo ImageUploader.app, 'change:patient', @updateVisitsSelectbox

  updateImageCount: ->
    @$('.image-count').html(@model.get('imageCount'))

  updateDateTime: =>
    @$('.datetime').html(@model.get('seriesDateTime'))

  updateUploadState: =>
    state = @model.get('uploadState')
    progress = @model.get('uploadProgress')
    @$('.upload-state .progress').toggleClass('parsed', state is 'parsed')
    @$('.upload-state .progress').toggleClass('uploading', state is 'uploading')
    @$('.upload-state .progress').toggleClass('uploaded', state is 'uploaded')
    @$('.upload-state .progress-bar').css width: "#{progress}%"
    @$('.upload-state .label').html(@model.getUploadStateLabel())

  stopPropagation: (e) ->
    e.stopPropagation()

  clickImageSeries: (e) =>
    if e.ctrlKey
      return if @model.get('disabled')

      marked = @model.get('markedForUpload')
      @model.set markedForUpload: not marked
    else
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
    @$('tr.image-series td.upload-flag input').prop('checked', marked)
    @renderVisitsSelectbox()

  renderVisitsSelectbox: =>
    @$('select.visit').select2
      width: '200px'
      placeholder: 'No visit assigned'
      allowClear: true
      ajax:
        cache: true
        url: ->
          "/v1/patients/#{ImageUploader.app.get('patient')?.id}/visits.json"
        data: (params) ->
          return { filter: params.term }
        processResults: (data, params) =>
          @visits = {}
          results = []
          results.push(id: 'create', text: 'Create New Visit') if currentUser.can('create', 'Visit')
          results = results.concat _.map data, (visit) =>
            @visits[visit.id] = visit
            {
              id: visit.id
              text: "#{visit.visit_number} — #{visit.visit_type or 'no visit type'}"
            }
          return { results: results }
      @$('select.visit')
        .prop('disabled', not @model.get('markedForUpload'))
        .trigger('change')

  updateVisitsSelectbox: (model) =>
    changed = model.changedAttributes()

    $select = @$('select.visit')
    $select.prop('disabled', not @model.get('markedForUpload'))
    $select.val('') if 'patient' of changed
    $select.trigger('change')

  massAssignVisit: (item) ->
    return if @model.get('disabled')

    @visits[item.id] = item.visit
    option = new Option(item.text, item.id, true, true)
    @$('select.visit').append(option)
    @$('select.visit')
      .val(item.id)
      .trigger('change')

  renderRequiredSeriesSelectbox: =>
    @$('select.required-series')
      .select2
        placeholder: 'No required series assigned'
        width: '250px'
    @$('select.required-series')
      .prop('disabled', not @model.get('markedForUpload') or not @model.get('assignVisitId')?)
      .trigger('change')

  updateRequiredSeriesSelectbox: (model) =>
    changed = model.changedAttributes()

    $select = @$('select.required-series')
    if 'assignVisitId' of changed
      if changed.assignVisitId?
        $select.html('').select2
          placeholder: 'No required series assigned'
          data: @visits[changed.assignVisitId]?.required_series or []
          width: '250px'
      else
        $select.html('').select2
          placeholder: 'No required series assigned'
          width: '250px'
      $select.val([])

    $select.prop('disabled', not @model.get('markedForUpload') or not @model.get('assignVisitId')?)
    $select.trigger('change')

  renderWarnings: =>
    @$('tr.image-series').toggleClass('has-warnings', @model.hasWarnings())

  renderDisabled: ->
    @$('tr.image-series td.upload-flag input').prop('disabled', @model.get('disabled'))

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
