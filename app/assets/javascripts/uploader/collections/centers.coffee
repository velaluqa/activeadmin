@ImageUploader ?= {}
@ImageUploader.Collections ?= {}
class ImageUploader.Collections.Centers extends Backbone.Collection
  url: => "/studies/#{@studyId}/centers.json"
  model: ImageUploader.Models.Center

  comparator: (model1, model2) ->
    naturalSort.insensitive = true
    naturalSort(model1.text(), model2.text())
