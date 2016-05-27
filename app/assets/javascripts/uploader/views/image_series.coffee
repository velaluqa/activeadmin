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

  updateImageCount: ->
    @$('.image-count').html(@model.get('imageCount'))

  updateDateTime: =>
    @$('.datetime').html(@model.get('seriesDateTime'))

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

    @$('td.date input').datepicker
      autoclose: true

    images = new ImageUploader.Views.Images
      el: @$('tr.images td')
      collection: @model.images
    images.render()

    this
