@ImageUploader ?= {}
@ImageUploader.Collections ?= {}
class ImageUploader.Collections.Patients extends Backbone.Collection
  url: -> "/centers/#{@centerId}/patients.json"
  model: ImageUploader.Models.Patient

  text: ->
    @get('subject')
