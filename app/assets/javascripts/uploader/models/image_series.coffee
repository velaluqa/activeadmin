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

  initialize: ->
    @images = new ImageUploader.Collections.Images()
    @updateImageCount()
    @listenTo @images, 'add', @updateImageCount
    @listenTo @images, 'remove', @updateImageCount
    @listenTo @images, 'change:state', @updateState

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

  push: (image) ->
    image.series = this
    @images.push(image)

  toJSON: (options = {}) ->
    return {
      id: @attributes.id,
      name: @attributes.name,
      state: @attributes.state,
      patient_id: @attributes.patient_id,
      imaging_date: @attributes.seriesDateTime,
      series_number: @attributes.seriesNumber
    }

  saveAsImported: ->
    console.log 'save as imported'
    @save(state: 'imported')
