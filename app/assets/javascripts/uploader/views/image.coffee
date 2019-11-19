@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.Image extends Backbone.View
  template: JST['uploader/templates/image']
  warningsListTemplate: JST['uploader/templates/warnings_list']

  tagName: 'tr'
  className: 'image'

  initialize: ->
    @listenTo @model, 'change:fileName', @renderName
    @listenTo @model, 'change:fileSize', @renderSize
    @listenTo @model, 'change:state', @renderState
    @listenTo @model, 'warnings', @renderWarnings

  renderName: =>
    @$('td.name').html(@model.get('fileName'))

  renderSize: =>
    @$('td.size').html(@model.get('fileSize'))

  renderState: =>
    @$('td.status').attr(class: "#{@model.get('state')} status")
    @$('td.status').html(@model.get('state'))

  renderWarnings: =>
    @$el.toggleClass('has-errors', @model.hasErrors())
    @$el.toggleClass('has-warnings', @model.hasWarnings())

  render: =>
    @$el.html(@template())
    @renderName()
    @renderSize()
    @renderState()

    @renderWarnings()
    @$('a[data-toggle=popover]').popover
      placement: 'left'
      html: true
      content: =>
        @warningsListTemplate(warnings: @model.formatWarnings())

    this
