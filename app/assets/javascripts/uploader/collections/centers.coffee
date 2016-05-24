@ImageUploader ?= {}
@ImageUploader.Collections ?= {}
class ImageUploader.Collections.Centers extends Backbone.Collection
  url: => "/studies/#{@studyId}/centers.json"
  model: ImageUploader.Models.Center
