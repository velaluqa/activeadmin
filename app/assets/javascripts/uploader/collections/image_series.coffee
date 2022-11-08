@ImageUploader ?= {}
@ImageUploader.Collections ?= {}
class ImageUploader.Collections.ImageSeries extends Backbone.Collection
  comparator: (model1, model2) ->
    naturalSort.insensitive = true
    naturalSort(model1.attributes.name, model2.attributes.name)

  findOrCreate: (options = {}) ->
    if options.instanceUid?
      series = @findWhere(instanceUid: options.instanceUid)
      return series if series?

    options.name = "Unnamed" unless options.name?

    series = new ImageUploader.Models.ImageSeries
      name: options.name
      instanceUid: options.instanceUid
    @add(series)
    series

  addImage: (image) =>
    series = @findOrCreate
      name: image.get('seriesDescription')
      instanceUid: if image.get('numberOfFrames') > 1 then image.get('sopInstanceUid') else image.get('seriesInstanceUid')

    unless series.get('seriesDateTime')?
      series.set(seriesDateTime: image.get('seriesDateTime'))
    unless series.get('imagingDateTime')?
      series.set(imagingDateTime: image.imagingDateTime())
    unless series.get('seriesNumber')?
      series.set(seriesNumber: image.get('seriesNumber'))
    series.add(image)
