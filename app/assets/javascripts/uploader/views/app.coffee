@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.App extends Backbone.View
  events:
    'click button': 'startUpload'

  initialize: ->
    @subviews ?= {}

  startUpload: =>
    @model.startUpload()

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
    view.render()

    @subviews.patientSelect = view = new ImageUploader.Views.ResourceSelect
      el: @$('#patient-select')
      model: @model
      selectableAttribute: 'patient'
      selectableCollection: 'patients'
    view.render()

    @subviews.imageSeries = view = new ImageUploader.Views.ImageSeriesTable
      el: @$('#image-series .panel_contents')
      model: @model
    view.render()
