@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ImageSeries extends Backbone.View
  template: JST['uploader/templates/image_series']
  tagName: 'tbody'
  className: 'image-series'

  events:
    'click tr.image-series': 'toggleShowImages'

  initialize: ->
    @listenTo @model, 'change:imageCount', @updateImageCount
    @listenTo @model, 'change:showImages', @showHideImages
    @listenTo @model, 'change:seriesDateTime', @updateDateTime
    @listenTo @model, 'change:imageCount change:uploadState change:uploadProgress', @updateUploadState

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

  toggleShowImages: (e) =>
    return if $(e.target).hasClass('hasDatepicker')
    @model.set(showImages: not @model.get('showImages'))

  showHideImages: =>
    @$el.toggleClass('show-images', @model.get('showImages') is true)

  render: =>
    @$el.html @template
      name: @model.get('name')
      imageCount: @model.get('imageCount')
      seriesDateTime: @model.get('seriesDateTime')

    @updateUploadState()

    images = new ImageUploader.Views.Images
      el: @$('tr.images td')
      collection: @model.images
    images.render()

    this
