@ImageUploader ?= {}
@ImageUploader.Models ?= {}
class ImageUploader.Models.Patient extends Backbone.Model
  text: ->
    @get('subject_id')

  match: (term) ->
    @text().match(///#{term}///i)?
