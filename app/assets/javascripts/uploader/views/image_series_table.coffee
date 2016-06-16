@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ImageSeriesTable extends Backbone.View
  template: JST['uploader/templates/image_series_table']

  initialize: ->
    @subviews = {}
    @listenTo @model.imageSeries, 'add', @appendImageSeries

  appendImageSeries: (series) =>
    name = series.get('name')
    @subviews[name] = view = new ImageUploader.Views.ImageSeries
      model: series
    @$table.append(view.render().el)

  render: =>
    @$el.html(@template())
    @$table = @$('table')

    @model.imageSeries.each @appendImageSeries

    this
