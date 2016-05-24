@ImageUploader ?= {}
@ImageUploader.Collections ?= {}
class ImageUploader.Collections.Studies extends Backbone.Collection
  url: '/studies.json'
  model: ImageUploader.Models.Study

  text: ->
    @get('name')
