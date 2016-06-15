@ImageUploader ?= {}
@ImageUploader.Collections ?= {}
class ImageUploader.Collections.Images extends Backbone.Collection
  comparator: (model1, model2) ->
    naturalSort.insensitive = true
    naturalSort(model1.attributes.fileName, model2.attributes.fileName)
