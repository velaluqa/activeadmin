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
    @listenTo @imageSeries, 'change:assignRequiredSeries change:assignVisitId', @validate

    @fileParser = new ImageUploader.Models.FileParser()
    @listenTo @fileParser, 'parsed', @imageSeries.addImage

  validate: =>
    for series in @imageSeries.models
      warnings = []
      allSeriesSameVisit = @imageSeries.where(assignVisitId: series.get('assignVisitId'))
      for seriesSameVisit in allSeriesSameVisit when seriesSameVisit isnt series
        intersection = _.intersection(series.get('assignRequiredSeries'), seriesSameVisit.get('assignRequiredSeries'))
        if intersection.length > 0
          warnings.push "Required series (#{intersection.join(', ')}) were assigned multiple times for the same visit."
      if warnings.length
        series.setWarnings('validation', warnings)
      else
        series.clearWarnings('validation')

  studySelected: (_, study) =>
    @set(center: null)
    @centers.studyId = @get('study').id
    @centers.reset()
    @centers.fetch()
    history.pushState({}, '', @urlQuery())

  centerSelected: (_, center) =>
    @set(patient: null)
    if center?
      @patients.centerId = center.id
      @patients.reset([])
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

    if @imageSeries.some((series) -> series.hasWarnings('validation'))
      return bootbox.alert('Some image series have validation warnings. Please check them and try again.')

    seriesSaved = []
    for series in @imageSeries.where(markedForUpload: true)
      seriesSaved.push series.createWithPatientId(@get('patient').get('id'))

    Promise.all(seriesSaved)
      .then =>
        seriesCompleted = for series in @imageSeries.where(markedForUpload: true)
          do (series) ->
            # A list of promises. When the whole series is uploaded, we
            # can assign the visit and the required series.
            seriesUploads = series.images.map (image) ->
              return if image.get('state') is 'uploaded'
              uploadQueue.push -> image.upload()

            Promise.all(seriesUploads)
              .then ->
                return unless series.get('state') is 'importing'
                series.saveAsImported()
              .then ->
                return unless currentUser.can('assign_visit', 'ImageSeries')
                return unless series.get('state') is 'imported'
                series.saveAssignedVisit()
              .then ->
                return unless currentUser.can('assign_visit', 'ImageSeries') and currentUser.can('assign_required_series', 'Visit')
                return unless series.get('state') is 'visit_assigned'
                series.saveAssignedRequiredSeries()
              .then ->
                series.set
                  markedForUpload: false
                  disabled: true
              .catch ->
                # ignore warnings here
        Promise.all([seriesCompleted..., uploadQueue.start()])
      .then =>
        hasErrors = @imageSeries.some (series) -> series.hasErrors()
        if hasErrors
          bootbox.alert('Something went wrong with the upload. Please check the error messages.')
        else
          bootbox.alert('Upload complete!')
