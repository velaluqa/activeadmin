@ImageUploader ?= {}
@ImageUploader.Collections ?= {}
class ImageUploader.Collections.ImageSeries extends Backbone.Collection
  findOrCreate: (options = {}) ->
    series = @findWhere(instanceUid: options.instanceUid)
    return series if series?

    series = new ImageUploader.Models.ImageSeries
      name: options.name
      instanceUid: options.instanceUid
    @add(series)
    series

  addImage: (image) =>
    series = @findOrCreate
      name: image.get('seriesDescription')
      instanceUid: image.get('seriesInstanceUid')
    unless series.get('seriesDateTime')?
      series.set(seriesDateTime: image.get('seriesDateTime'))
    unless series.get('seriesNumber')?
      series.set(seriesNumber: image.get('seriesNumber'))
    series.push(image)
