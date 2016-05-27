@ImageUploader ?= {}
@ImageUploader.Models ?= {}
class ImageUploader.Models.App extends Backbone.Model
  defaults:
    # Selected Models
    study: null
    center: null
    patient: null

  initialize: ->
    @studies = new ImageUploader.Collections.Studies()
    @centers = new ImageUploader.Collections.Centers()
    @patients = new ImageUploader.Collections.Patients()

    @on 'change:study', @studySelected
    @on 'change:center', @centerSelected
    @on 'change:patient', @patientSelected

    initial =
      study: parseInt(getParameterByName('study_id') or -1)
      center: parseInt(getParameterByName('center_id') or -1)
      patient: parseInt(getParameterByName('patient_id') or -1)

    @listenTo @studies, 'sync', =>
      if @studies.size() is 1
        study = @studies.first()
      else if initial.study isnt -1
        study = @studies.findWhere(id: initial.study)
        initial.study = null
      @set study: study if study?
    @listenTo @centers, 'sync', =>
      if @centers.size() is 1
        center = @centers.first()
      else if initial.center isnt -1
        center = @centers.findWhere(id: initial.center)
        initial.center = null
      @set center: center if center?
    @listenTo @patients, 'sync', =>
      if @patients.size() is 1
        patient = @patients.first()
      else if initial.patient isnt -1
        patient = @patients.findWhere(id: initial.patient)
        initial.patient = null
      @set patient: patient if patient?

    @studies.fetch()

    @imageSeries = new ImageUploader.Collections.ImageSeries()
    @parsingCollection = new ImageUploader.Models.ImageSeries(name: 'Parsing')
    @listenTo @parsingCollection.images, 'change:state', @regroupParsedImage

  studySelected: (_, study) =>
    @set(center: null)
    @centers.studyId = @get('study').id
    @centers.fetch()
    history.pushState({}, '', @urlQuery())

  centerSelected: (_, center) =>
    @set(patient: null)
    if center?
      @patients.centerId = center.id
      @patients.fetch()
    else
      @patients.reset([])
    history.pushState({}, '', @urlQuery())

  patientSelected: =>
    history.pushState({}, '', @urlQuery())

  addDataTransferItems: (items) =>
    for item in items
      switch item.kind
        when 'file' then @addFile(item)
        when 'directory' then @addDirectory(item)

  addFile: (item) =>
    entry = item.webkitGetAsEntry()
    image = new ImageUploader.Models.Image
      fileName: entry.fullPath
      fsName: entry.filesystem.name
    @parsingCollection.push(image)
    image.parse(item)

  addDirectory: (item) ->
    console.log 'dir', item

  findOrCreateImageSeries: (name) ->
    series = @imageSeries.findWhere(name: name)
    return series if series?

    series = new ImageUploader.Models.ImageSeries(name: name)
    @imageSeries.push(series)
    series

  regroupParsedImage: (image) ->
    @parsingCollection.images.remove(image)
    series = @findOrCreateImageSeries(image.get('seriesDescription'))
    series.push(image)

  urlQuery: =>
    query = []
    query.push("study_id=#{@get('study').id}") if @get('study')
    query.push("center_id=#{@get('center').id}") if @get('center')
    query.push("patient_id=#{@get('patient').id}") if @get('patient')
    "?#{query.join('&')}"
