@ImageUploader ?= {}
@ImageUploader.Models ?= {}
class ImageUploader.Models.ImageSeries extends Backbone.Model
  url: '/v1/image_series.json'

  initialize: ->
    @images = new ImageUploader.Collections.Images()
    @updateImageCount()
    @listenTo @images, 'add', @updateImageCount
    @listenTo @images, 'remove', @updateImageCount

  updateImageCount: =>
    @set imageCount: @images.size()

  push: (image) ->
    @images.push(image)
