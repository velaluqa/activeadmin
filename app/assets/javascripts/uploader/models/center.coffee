@ImageUploader ?= {}
@ImageUploader.Models ?= {}
class ImageUploader.Models.Center extends Backbone.Model
  text: ->
    @get('name')

  match: (term) ->
    @text().match(///#{term}///i)?
