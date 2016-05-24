@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ResourceSelect extends Backbone.View
  events:
    'input .filter': 'filter'

  initialize: (options = {}) ->
    @subviews = {}

    @selectableAttribute = options.selectableAttribute
    @selectableCollection = options.selectableCollection

    @collection = @model[@selectableCollection]

    @listenTo @collection, 'sync', @render
    @listenTo @collection, 'reset', @render

  select: (model) =>
    @model.set @selectableAttribute, $(e.target).attr('data')

  filter: (e) =>
    val = $(e.target).val()
    _.invoke(@subviews, 'filter', val)

  render: =>
    $panelContents = @$('.panel-contents')
    $list = $('<ul>', class: @selectableCollection)
    @collection.each (model, i) =>
      @subviews["entry#{i}"] = view = new ImageUploader.Views.ResourceSelectEntry
        model: model
        select: this
      $list.append(view.render().el)
    $panelContents.html($list)
