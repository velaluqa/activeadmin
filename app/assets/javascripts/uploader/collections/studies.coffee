@ImageUploader ?= {}
@ImageUploader.Collections ?= {}
class ImageUploader.Collections.Studies extends Backbone.Collection
  url: '/studies.json'
  model: ImageUploader.Models.Study

  comparator: (model1, model2) ->
    naturalSort.insensitive = true
    naturalSort(model1.text(), model2.text())
