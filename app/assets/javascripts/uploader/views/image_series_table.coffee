@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ImageSeriesTable extends Backbone.View
  template: JST['uploader/templates/image_series_table']

  initialize: ->
    dropzone = document.getElementById('drop-image-series')
    dropzone.addEventListener 'dragover', @dragover, false
    dropzone.addEventListener 'drop', @drop, false

    @subviews = {}
    @listenTo @model.imageSeries, 'add', @appendImageSeries

  appendImageSeries: (series) =>
    name = series.get('name')
    @subviews[name] = view = new ImageUploader.Views.ImageSeries
      model: series
    @$table.append(view.render().el)

  dragover: (e) ->
    e.stopPropagation()
    e.preventDefault()
    e.dataTransfer.dropEffect = 'copy'

  drop: (e) =>
    e.stopPropagation()
    e.preventDefault()
    @model.addDataTransferItems(e.dataTransfer.items)

  render: =>
    @$el.html(@template())
    @$table = @$('table')

    @appendImageSeries(@model.parsingCollection)
    @model.imageSeries.each @appendImageSeries

    this
