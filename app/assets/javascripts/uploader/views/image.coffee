@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.Image extends Backbone.View
  template: JST['uploader/templates/image']

  tagName: 'tr'
  className: 'image'

  initialize: ->
    @listenTo @model, 'change', @render

  render: =>
    @$el.html @template @model.toJSON()
    this
