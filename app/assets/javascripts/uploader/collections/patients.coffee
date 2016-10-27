@ImageUploader ?= {}
@ImageUploader.Collections ?= {}
class ImageUploader.Collections.Patients extends Backbone.Collection
  url: -> "/centers/#{@centerId}/patients.json"
  model: ImageUploader.Models.Patient

  comparator: (model1, model2) ->
    naturalSort.insensitive = true
    naturalSort(model1.text(), model2.text())
