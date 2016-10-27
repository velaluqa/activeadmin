@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ResourceSelectEntry extends Backbone.View
  tagName: 'li'
  className: 'entry'

  events:
    'click': 'select'

  initialize: (options = {}) =>
    @select = options.select
    @mainModel = @select.model

    @listenTo @mainModel, "change:#{@select.selectableAttribute}", @renderState

  select: =>
    @mainModel.set(@select.selectableAttribute, @model)

  selectedModel: ->
    @mainModel.get(@select.selectableAttribute)

  isSelected: ->
    @model is @selectedModel()

  renderState: =>
    if @selectedModel()?
      @$el.toggleClass('inactive', not @isSelected())
      @$el.toggleClass('active', @isSelected())

  filter: (term) =>
    @$el.toggleClass('hidden', not @model.match(term))

  render: =>
    @renderState()
    @$el.html(@model.text())
    this
