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
    image.series = this
    @images.push(image)

  toJSON: (options = {}) ->
    return {
      id: @attributes.id,
      name: @attributes.name,
      patient_id: @attributes.patient_id,
      imaging_date: @attributes.seriesDateTime,
      series_number: @attributes.seriesNumber
    }
