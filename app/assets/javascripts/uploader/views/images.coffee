@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.Images extends Backbone.View
  template: JST['uploader/templates/images']

  initialize: ->
    @subviews = {}
    @listenTo @collection, 'add', @append
    @listenTo @collection, 'remove', @remove

  append: (image) =>
    index = @collection.indexOf(image)
    @subviews[image.get('fileName')] = view = new ImageUploader.Views.Image
      model: image

    $previous = @$tbody.children().eq(index)
    if $previous.length > 0
      $previous.before(view.render().el)
    else
      @$tbody.append(view.render().el)

  remove: (image) =>
    @subviews[image.get('fileName')].remove()

  render: =>
    @$el.html(@template())
    @$tbody = @$('table tbody')
    @collection.each @append
    this
