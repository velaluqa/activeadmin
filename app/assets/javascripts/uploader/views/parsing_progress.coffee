@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ParsingProgress extends Backbone.View
  events:
    'change #folders': 'addFolders'

  initialize: ->
    dropzone = document.body
    dropzone.addEventListener 'dragover', @dragover, false
    dropzone.addEventListener 'drop', @drop, false

    @parser = @model.fileParser

    @listenTo @parser, 'change:state parsed', @renderParsingProgress
    @listenTo ImageUploader.app, 'change:patient', @renderDisabled

  dragover: (e) ->
    e.stopPropagation()
    e.preventDefault()
    e.dataTransfer.dropEffect = 'copy'

  drop: (e) =>
    e.stopPropagation()
    e.preventDefault()
    entries = (item.webkitGetAsEntry() for item in e.dataTransfer.items)
    @parser.addFsEntries(entries)

  addFolders: (e) =>
    @parser.addFile(file) for file in e.target.files

  renderParsingProgress: =>
    state = @parser.get('state')
    progress = @parser.progress()
    parsedFiles = @parser.parsedFiles
    totalFiles = @parser.totalFiles
    if state is 'idle'
      requestAnimationFrame =>
        @$('.progress .progress-bar').css width: "#{progress}%"
        @$el.toggleClass('parsing', true)
        @$el.toggleClass('parsed', true)
        @$('.progress .label').html("Parsed #{totalFiles} files")
      setTimeout =>
        @$el.toggleClass('parsing', false)
        @$el.toggleClass('parsed', false)
        @$('.progress .progress-bar').css width: "0%"
      , 1000
    else
      requestAnimationFrame =>
        @$('.progress .progress-bar').css width: "#{progress}%"
        @$el.toggleClass('parsing', true)
        @$('.progress .label').html("Parsing #{parsedFiles} / #{totalFiles} files")

  renderDisabled: =>
    @$el.toggleClass('disabled', not ImageUploader.app.get('patient')?)

  render: ->
    @renderParsingProgress()
    @renderDisabled()
    this
