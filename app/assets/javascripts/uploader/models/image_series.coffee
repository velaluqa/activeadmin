@ImageUploader ?= {}
@ImageUploader.Models ?= {}
class ImageUploader.Models.ImageSeries extends Backbone.Model
  url: ->
    id = @get('id')
    if id?
      "/v1/image_series/#{id}.json"
    else
      '/v1/image_series.json'

  defaults:
    uploadState: 'parsed'
    uploadProgress: 20
    state: 'importing'
    disabled: false

  initialize: ->
    @warnings = {}
    @images = new ImageUploader.Collections.Images()
    @updateImageCount()
    @listenTo @images, 'add remove', @updateImageCount
    @listenTo @images, 'add remove', @updateWarnings
    @listenTo @images, 'change:state', @updateState
    @listenTo @images, 'warnings', => @trigger('warnings')

  updateWarnings: (image) ->
    @trigger('warnings') if image.hasWarnings()

  hasWarnings: (type) ->
    if type?
      return not _.isEmpty(@warnings[type])
    hasSeriesWarnings = not _.isEmpty(@warnings)
    hasSeriesWarnings or @images.some (image) -> image.hasWarnings()

  formatWarnings: ->
    strings = _
      .chain(@warnings)
      .map (warnings, action) ->
        return [] unless warnings?
        _(warnings).map (warning) -> "#{action.capitalize()}: #{warning}"
      .flatten()
      .value()
    imageWarnings = @images
      .select (image) -> image.hasWarnings()
      .length
    if imageWarnings
      strings.push("Warnings for #{imageWarnings} images")
    strings

  setWarnings: (action, warnings) ->
    @warnings[action] = Array.ensureArray(warnings)
    @trigger('warnings')

  pushWarnings: (action, warnings) ->
    warnings = Array.ensureArray(warnings)
    @warnings[action] ?= []
    for warning in warnings when warning not in @warnings[action]
      @warnings[action].push(warning)
    @trigger('warnings')

  clearWarnings: (action) ->
    delete @warnings[action]
    @trigger('warnings')

  updateState: (image, state) =>
    count = @images.size()
    uploadedCount = @images.where(state: 'uploaded').length
    uploadingCount = @images.where(state: 'uploading').length
    parsedCount = @images.where(state: 'parsed').length
    if parsedCount is count
      @set
        uploadState: 'parsed'
        uploadProgress: 0
        uploadingCount: uploadingCount
        uploadedCount: uploadedCount
        parsedCount: parsedCount
    else if uploadedCount is count
      @set
        uploadState: 'uploaded'
        uploadProgress: 100
        uploadingCount: uploadingCount
        uploadedCount: uploadedCount
        parsedCount: parsedCount
    else if uploadingCount isnt 0
      @set
        uploadState: 'uploading'
        uploadProgress: (uploadedCount / count * 100)
        uploadingCount: uploadingCount
        uploadedCount: uploadedCount
        parsedCount: parsedCount

  updateImageCount: =>
    @set imageCount: @images.size()
    @updateState()

  getUploadStateLabel: ->
    state = @get('uploadState')
    uploadedCount = @get('uploadedCount')
    count = @images.size()
    switch state
      when 'parsed'
        return "Parsed (#{count})"
      when 'uploading'
        return "Uploading (#{uploadedCount} / #{count})"
      when 'uploaded'
        return "Uploaded (#{count})"

  add: (image) ->
    image.series = this
    @images.add(image)

  toJSON: (options = {}) ->
    return {
      id: @attributes.id,
      name: @attributes.name,
      patient_id: @attributes.patient_id,
      imaging_date: @attributes.seriesDateTime,
      series_number: @attributes.seriesNumber,
      visit_id: @attributes.visit_id
    }

  createWithPatientId: (patientId) ->
    return unless @isNew()

    @save { patient_id: patientId },
      success: =>
        @set state: 'importing'
        @clearWarnings('create')
      error: (_, response) =>
        console.log response.responseJSON?.errors
        @pushWarnings('create', response.responseJSON?.errors)

  saveAsImported: ->
    request =
      type: 'POST'
      url: "/v1/image_series/#{@get('id')}/finish_import.json"
      data:
        expected_image_count: @images.size()
      success: =>
        @clearWarnings('finish import')
      error: (response) =>
        @pushWarnings('finish import', response.responseJSON?.errors)
      cache: false

    $.ajax(request).then =>
      @set state: 'imported'

  saveAssignedVisit: ->
    return unless @get('assignVisitId')?
    attributes =

    @save { visit_id: @get('assignVisitId') },
      patch: true
      success: =>
        @set state: 'visit_assigned'
        @clearWarnings('assign visit')
      error: (_, response) =>
        @pushWarnings('assign visit', response.responseJSON?.errors)

  saveAssignedRequiredSeries: ->
    return unless @get('assignRequiredSeries')?
    return unless @get('assignRequiredSeries').length
    request =
      type: 'POST'
      url: "/v1/image_series/#{@get('id')}/assign_required_series.json"
      data:
        required_series: @get('assignRequiredSeries')
      success: =>
        @clearWarnings('assign required series')
      error: (response) =>
        @pushWarnings('assign required series', response.responseJSON?.errors)
      cache: false

    $.ajax(request).then =>
      @set(state: 'required_series_assigned')
