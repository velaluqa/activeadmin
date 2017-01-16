@Dashboard ?= {}
@Dashboard.Views ?= {}
class Dashboard.Views.Row extends Backbone.View
  className: 'row'
  template: JST['dashboard/templates/row']

  events:
    'sortout': 'sortOut'
    'sortover': 'sortOver'

  sortOut: =>
    len = @$('ul.row li:not(.ui-sortable-helper):not(.sortable-placeholder)').length
    @setSizeClass(len)

  sortOver: =>
    len = @$('ul.row li:not(.ui-sortable-helper)').length
    @setSizeClass(len)

  initialize: ->
    @subviews ||= {}
    @listenTo @model.widgets, 'add remove', =>
      @setSizeClass(@model.widgets.length)
    @listenTo window.dashboard, 'change:editing', @setSortableOptions

  setSizeClass: (count) =>
    items = @model.widgets.length
    if count > 6
      @$el.attr(class: 'row size-6')
    else if count < 1
      @$el.attr(class: 'row empty')
    else
      @$el.attr(class: "row size-#{count}")

  setSortableOptions: (_, editing) =>
    @collectionView.setOptions(sortable: editing)

  render: =>
    @setSizeClass(@model.widgets.length)
    @$el.html(@template())
    @collectionView = new Backbone.CollectionView
      el: @$('ul')
      selectable: false
      sortable: window.dashboard.get('editing')
      sortableOptions:
        axis: 'xy'
        connectWith: '.row'
        forcePlaceholderSize: false
        opacity: 0.6
        placeholder: 'sortable-placeholder'
      collection: @model.widgets
      modelView: Dashboard.Views.Widget
    @collectionView.render()
    @$('ul').disableSelection()
    this
