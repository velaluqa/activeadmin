@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.App extends Backbone.View
  events:
    'click button': 'startUpload'

  initialize: ->
    @subviews ?= {}

    @listenTo ImageUploader.app, 'change:patient', @renderDisabled

  startUpload: =>
    @model.startUpload()

  renderDisabled: =>
    @$('button').prop('disabled', not ImageUploader.app.get('patient')?)

  render: =>
    @subviews.studySelect = view = new ImageUploader.Views.ResourceSelect
      el: @$('#study-select')
      model: @model
      selectableAttribute: 'study'
      selectableCollection: 'studies'
    view.render()

    @subviews.centerSelect = view = new ImageUploader.Views.ResourceSelect
      el: @$('#center-select')
      model: @model
      selectableAttribute: 'center'
      selectableCollection: 'centers'
      dependentAttribute: 'study'
      creatableResource: 'Center'
      creationUrl: (model) ->
        "/admin/centers/new?study_id=#{model.get('study').id}"
    view.render()

    @subviews.patientSelect = view = new ImageUploader.Views.ResourceSelect
      el: @$('#patient-select')
      model: @model
      selectableAttribute: 'patient'
      selectableCollection: 'patients'
      dependentAttribute: 'center'
      creatableResource: 'Patient'
      creationUrl: (model) ->
        "/admin/patients/new?center_id=#{model.get('center').id}"
    view.render()

    @subviews.parsingProgress = view = new ImageUploader.Views.ParsingProgress
      el: @$('#parse-images')
      model: @model
    view.render()

    @subviews.imageSeries = view = new ImageUploader.Views.ImageSeriesTable
      el: @$('#image-series')
      model: @model
    view.render()

    @renderDisabled()

    this
