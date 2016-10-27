@ImageUploader ?= {}
@ImageUploader.Models ?= {}
class ImageUploader.Models.Study extends Backbone.Model
  text: ->
    @get('name')

  match: (term) ->
    @text().match(///#{term}///i)?
