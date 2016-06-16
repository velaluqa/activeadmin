@ImageUploader ?= {}
@ImageUploader.Models ?= {}
class ImageUploader.Models.FileParser extends Backbone.Model
  defaults: ->
    state: 'idle'

  initialize: ->
    @files = new ImageUploader.Collections.Images()
    @failed = []

    @totalFiles = 0
    @parsedFiles = 0

    @listenTo @files, 'add', @handleAdd
    @listenTo @files, 'remove', @handleRemove
    @listenTo @files, 'change:state', @handleStateChange

  parse: (image, file) ->
    @files.push(image)
    setTimeout ->
      image.parse(file)
    , 100

  progress: ->
    @parsedFiles / @totalFiles * 100

  handleAdd: =>
    if @get('state') is 'idle'
      @parsedFiles = 0
      @totalFiles = 0
    @set state: 'parsing'
    @totalFiles += 1

  handleRemove: =>
    if @files.size() is 0
      @set state: 'idle'
      fileNames = _.map @failed, (image) -> image.get('fileName')
      unless _.isEmpty(@failed)
        alert("Failed parsing some files: #{fileNames.join(', ')}")
        @failed = []

  handleStateChange: (model, state) =>
    if state is 'parsed'
      @trigger 'parsed', model
    else
      @failed.push(model)
    @parsedFiles += 1
    @files.remove(model)

  addFsEntries: (entries) =>
    for entry in entries
      entry.file(@addFile) if entry.isFile
      @addDirectory(entry) if entry.isDirectory

  addFile: (file) =>
    return if file.name.endsWith('DICOMDIR')

    image = new ImageUploader.Models.Image
      fileName: file.name
      fileSize: file.size
    @parse(image, file)

  addDirectory: (entry) ->
    dirReader = entry.createReader()
    dirReader.readEntries @addFsEntries
