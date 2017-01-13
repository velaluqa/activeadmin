@Dashboard ?= {}
@Dashboard.Views ?= {}
class Dashboard.Views.Main extends Backbone.View
  initialize: ->
    @subviews ||= {}

  events:
    'sortstart': 'sortstart'
  sortstart: (_, ui) ->
    return unless ui.placeholder.hasClass('sortable-row-placeholder')
    height = ui.item.outerHeight()
    ui.placeholder.css height: "#{height}px"
  render: =>
    @$el.html('<ul class="rows"></ul>')
    collectionView = new Backbone.CollectionView
      el: @$('ul.rows')
      selectable: false
      sortable: true
      sortableOptions:
        axis: 'y'
        handle: '.row-sortable-handle'
        forcePlaceholderSize: true
        opacity: 0.6
        placeholder: 'sortable-row-placeholder'
      collection: @model.rows
      modelView: Dashboard.Views.Row
    collectionView.render()
    @$('ul.rows').disableSelection()
    @$el.append('<button class="add-row">Add Row</button>')
    this
