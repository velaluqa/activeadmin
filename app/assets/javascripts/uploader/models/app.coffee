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

    @fileParser = new ImageUploader.Models.FileParser()
    @listenTo @fileParser, 'parsed', @imageSeries.addImage

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

  urlQuery: =>
    query = []
    query.push("study_id=#{@get('study').id}") if @get('study')
    query.push("center_id=#{@get('center').id}") if @get('center')
    query.push("patient_id=#{@get('patient').id}") if @get('patient')
    "?#{query.join('&')}"

  startUpload: =>
    uploadQueue = new PromiseQueue(5)

    seriesSaved = []
    for series in @imageSeries.where(markedForUpload: true)
      series.set(patient_id: @get('patient').get('id'))
      continue unless series.isNew()
      seriesSaved.push series.save()

    Promise.all(seriesSaved)
      .then =>
        for series in @imageSeries.where(markedForUpload: true)
          # A list of promises. When the whole series is uploaded, we
          # can assign the visit and the required series.
          seriesUploads = []
          series.images.each (image) ->
            return if image.get('state') is 'uploaded'
            seriesUploads.push uploadQueue.push -> image.upload()

          Promise.all(seriesUploads)
            .then ->
              return unless series.get('state') is 'importing'
              series.saveAsImported()
            .then ->
              return unless series.get('state') is 'imported'
              series.saveAssignedVisit()
            .then ->
              return unless series.get('state') is 'visit_assigned'
              series.saveAssignedRequiredSeries()

        uploadQueue.start()
      .then ->
        console.log 'all uploads done'
