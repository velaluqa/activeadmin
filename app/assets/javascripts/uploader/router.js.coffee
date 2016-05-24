@getParameterByName = (name, url) ->
  url ||= window.location.href
  name = name.replace(/[\[\]]/g, '\\$&')
  regex = ///[?&]#{name}(=([^&#]*)|&|#|$)///
  results = regex.exec(url)

  return null unless results
  return '' unless results[2]

  decodeURIComponent(results[2].replace(/\+/g, ' '));

@ImageUploader ?= {}
class ImageUploader.Router extends Backbone.Router
  routes:
    '': 'index'

  initialize: ->
    ImageUploader.app = new ImageUploader.Models.App()
    ImageUploader.view = new ImageUploader.Views.App
      model: ImageUploader.app
      el: $('#image-upload')
    ImageUploader.view.render()
